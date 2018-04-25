require 'spec_helper'

feature User, 'Uploads organization documents:' do
  background do
    @user = FactoryGirl.create(:user)
    @catalog = create(:catalog, organization: @user.organization)
    create(:sector, title: 'Otros')
    create(:inventory, organization: @user.organization)
    given_logged_in_as(@user)
  end

  scenario 'uploads the designation file and the authorization file' do
    visit organization_documents_path(@user.organization)

    attach_and_upload_organization_documents

    expect(page).to have_text('designation_file.docx')
    expect(page).to have_text('memo_file.pdf')
    expect(page).not_to have_text('ministry_memo_file.pdf')
  end

  scenario 'after uploading the first document it creates de documents dataset' do
    visit organization_documents_path(@user.organization)
    attach_and_upload_organization_documents
    visit catalog_datasets_path(@catalog)

    expect(page).to have_text("Oficios y Documentos Institucionales de #{@user.organization.title}")
  end

  context 'ministry' do
    scenario 'uploads the designation file, authorization file and ministry memo file' do
      visit organization_documents_path(@user.organization)

      attach_and_upload_organization_documents

      expect(page).to have_text('designation_file.docx')
      expect(page).to have_text('memo_file.pdf')
    end
  end

  def attach_and_upload_organization_documents
    within('.edit_organization') do
      attach_designation_file
      attach_memo_file
      attach_ministry_memo_file if @user.organization.ministry?
      click_on('Subir documentos')
    end
  end

  def attach_designation_file
    attach_file('organization_designation_files_attributes_0_file', "#{Rails.root}/spec/fixtures/files/designation_file.docx")
  end

  def attach_memo_file
    attach_file('organization_memo_files_attributes_0_file', "#{Rails.root}/spec/fixtures/files/memo_file.pdf")
  end

  def attach_ministry_memo_file
    attach_file('organization_ministry_memo_files_attributes_0_file', "#{Rails.root}/spec/fixtures/files/ministry_memo_file.pdf")
  end
end
