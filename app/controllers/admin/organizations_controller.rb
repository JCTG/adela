require 'net/ftp'

module Admin
  class OrganizationsController < Admin::BaseController 

    load_and_authorize_resource except: [:update_multiple]

    def index
      @organizations = Organization.includes(:users).title_sorted.paginate(page: params[:page])
    end

    def new
      @organization = Organization.new
    end

    def create
      @organization = Organization.new(organization_params)
      @organization.build_inventory
      @organization.build_catalog
      if @organization.save
        flash[:notice] = I18n.t('flash.notice.organization.create')
        redirect_to admin_organizations_path
      else
        render 'new'
      end
      
    end

    def edit
      @organization = Organization.friendly.find(params[:id])
      @title = @organization.title
      @organization.build_administrator unless @organization.administrator
      @organization.build_liaison unless @organization.liaison
    end

    def update
      @organization = Organization.find(params[:id])
      @title = @organization.title
      oldname = @organization.slug

      if @organization.update(organization_params)
        flash[:notice] = I18n.t('flash.notice.organization.update')
            unless @title == params[:title]
                newname = @organization.slug
                ShogunUpdateorgWorker.perform_async(oldname, newname, @organization.title)  
                if oldname != newname 
                  cambio_org_ftp oldname, newname
                end        
            end  
        redirect_to admin_organizations_path
      else
        render 'edit'
      end
    end

    def cambio_org_ftp oldname , newname 
     begin
      path_base_desg_file = ENV['BASE_DESIGNATION_FILE']
      path_base_memo_file = ENV['BASE_MEMO_FILE']
      file_dir            = ENV['FOLDER_FILE']   
      old_path_designation_file = "#{path_base_desg_file}" + "#{oldname}" + "#{file_dir}"
      new_path_designation_file = "#{path_base_desg_file}" + "#{newname}" + "#{file_dir}"
      old_path_memo_file        = "#{path_base_memo_file}" + "#{oldname}" + "#{file_dir}"
      new_path_memo_file        = "#{path_base_memo_file}" + "#{newname}" + "#{file_dir}"
     
      create_new_structure_ftp  oldname , newname , old_path_designation_file
      create_new_structure_ftp  oldname , newname , old_path_memo_file
      copy_files old_path_designation_file , new_path_designation_file , oldname , newname
      copy_files old_path_memo_file        , new_path_memo_file        , oldname , newname
      delete_old_estructure_ftp oldname , newname , old_path_designation_file
      delete_old_estructure_ftp oldname , newname , old_path_memo_file
      msg = nil
      rescue EOFError => e
          msg = e.message 
      rescue SocketError => e
          msg = e.message
      rescue OpenURI::HTTPError => e
          msg = e.message 
      rescue Net::FTPPermError => e
          msg = e.message 
      rescue Net::SFTP::StatusException => e
          msg = e.message 
      rescue Errno::ETIMEDOUT => e
          msg = e.message 
      rescue Exception => e
          msg = e.message
      end

      if msg != nil
          gen_log_file oldname , newname , msg
      end
    end

    def edit_multiple
      @organizations = Organization.title_sorted
    end

    def update_multiple
      authorize! :update, Organization
      @success = Organization.update(params[:organizations].keys, params[:organizations].values)
    end

    private

    def organization_params
      params.require(:organization).permit(
        :title,
        :description,
        :landing_page,
        :gov_type,
        :ranked,
        :ministry,
        administrator_attributes: [:user_id],
        liaison_attributes: [:user_id],
        organization_sectors_attributes: [:id, :sector_id, :_destroy])
    end

    def create_new_structure_ftp oldname , newname , path
    Net::FTP.open(ENV['FTP_HOST'], user= ENV['FTP_USER'], passwd= ENV['FTP_PASSWD']) do |ftp|
      if (ftp.dir(path).length > 0 ) and ( oldname != newname )   
          ftp.chdir(path)
          ftp.binary = true
          old_path   = ftp.pwd
          folders    = []
          indice     = 0 
          estructura = ftp.nlst("*")
          folder_file = "file"
          estructura.each do |elem|    
              folders[indice]  = elem.split('/').first
              indice += 1 
          end
          ftp.chdir('../../')
          ftp.mkdir(newname)
          ftp.chdir(newname)      
          ftp.mkdir(folder_file)
          ftp.chdir(folder_file)
          folders.each do |folder|  
            ftp.mkdir(folder)
          end
        end
      ftp.close  
    end
    end

    def  copy_files old_path , new_path , oldname , newname
      Net::FTP.open(ENV['FTP_HOST'], user= ENV['FTP_USER'], passwd= ENV['FTP_PASSWD']) do |ftp|      
        if (ftp.dir(old_path).length > 0 ) and ( oldname != newname )
            ftp.chdir(old_path)
            files  = [] 
            indice = 0
            estructura = ftp.nlst("*")
            estructura.each do |elem|    
               files[indice]    = elem.split('/').first + "/" + elem.split('/').last
                indice += 1 
            end
            files.each do |elem|
              origen   = "#{old_path}" + "/" + elem 
              destino  = "#{new_path}" + "/" + elem  
              ftp.rename(origen, destino)
            end
           ftp.close
          end  
      end  
    end

    def delete_old_estructure_ftp oldname , newname ,path
      Net::FTP.open(ENV['FTP_HOST'], user= ENV['FTP_USER'], passwd= ENV['FTP_PASSWD']) do |ftp|   
        if (ftp.dir(path).length > 0 ) and ( oldname != newname )
          ftp.chdir(path)
          estructura =  ftp.nlst()
          estructura.each { |folder|
            ftp.rmdir(folder)  
          }
          ftp.chdir("../")
          ftp.rmdir("file")
          ftp.chdir("../")
          ftp.rmdir(oldname)   
        end
        ftp.close
      end   
    end
   
    def check_nueva_est_creada_ftp old_path_designation_file , old_path_memo_file
      existeOldStructure = false
      Net::FTP.open(ENV['FTP_HOST'], user= ENV['FTP_USER'], passwd= ENV['FTP_PASSWD']) do |ftp|   
        if ftp.dir(old_path_designation_file).length == 0 and ftp.dir(old_path_memo_file).length  == 0
             existeOldStructure = true
        end
        ftp.close
      end
      return existeOldStructure   
    end
      
    def  gen_log_file oldname , newname , msg 
       Net::FTP.open(ENV['FTP_HOST'], user= ENV['FTP_USER'], passwd= ENV['FTP_PASSWD']) do |ftp|   
        fileName =  "oldname_" + oldname + "_newname_" + newname + "_" +  "#{Time.parse(DateTime.now.to_s)}".gsub!(" ", "-")
        f = File.new("/tmp/#{fileName}", 'a')
        f.write(msg)
        f.close
        ftp.chdir(ENV['PATH_LOGS_CAMBIO_ORG'])      
        ftp.put("/tmp/#{fileName}")
        ftp.close
       end
    end
  end
end
