require 'spec_helper'

feature User, 'manages inventory:' do
  background do
    @user = FactoryGirl.create(:user)
    given_logged_in_as(@user)
  end

  scenario 'sees inventory card' do
    expect(page).to have_text('Planea')
    expect(page).to have_text('Descargar')
    expect(page).to have_text('Subir')
  end

  scenario 'uploads a valid inventory file' do
    click_on('Subir')
    attach_file('inventory_spreadsheet_file', "#{Rails.root}/spec/fixtures/files/inventario_general_de_datos.xlsx")
    click_on('Subir inventario')

    expect(page).to have_text("Inventario institucional de Datos de #{@user.organization.title}")
  end

  scenario 'uploads a valid inventory file and an authorization file' do
    click_on('Subir')
    attach_file('inventory_spreadsheet_file', "#{Rails.root}/spec/fixtures/files/inventario_general_de_datos.xlsx")
    attach_file('inventory_authorization_file', "#{Rails.root}/spec/fixtures/files/authorization_file.jpg")
    click_on('Subir inventario')

    expect(page).to have_text("Inventario institucional de Datos de #{@user.organization.title}")
  end

  scenario 'uploads an invalid inventory file with no comments for private datasets' do
    spreadsheet_file = File.new("#{Rails.root}/spec/fixtures/files/inventario_general_de_datos_error_privado.xlsx")
    inventory = create(:inventory, organization: @user.organization, spreadsheet_file: spreadsheet_file)
    InventoryXLSXParserWorker.new.perform(inventory.id)
    visit inventory_path(inventory)

    expect(page).to have_text('Se encontraron las siguientes observaciones en el archivo de Inventario de Datos:')
    expect(page).to have_text('Renglón 2')
    expect(page).to have_text('Cuando el valor del dato ¿Tiene datos privados? no es Público la columna F no puede estar vacía o nula.')
  end

  scenario 'uploads an invalid inventory file with no publish date for public datasets' do
    spreadsheet_file = File.new("#{Rails.root}/spec/fixtures/files/inventario_general_de_datos_error_publico.xlsx")
    inventory = create(:inventory, organization: @user.organization, spreadsheet_file: spreadsheet_file)
    InventoryXLSXParserWorker.new.perform(inventory.id)
    visit inventory_path(inventory)

    expect(page).to have_text('Se encontraron las siguientes observaciones en el archivo de Inventario de Datos:')
    expect(page).to have_text('Renglón 2')
    expect(page).to have_text('Cuando el valor del dato ¿Tiene datos privados? es Público la fecha estimada de publicación no puede estar vacía o nula.')
  end

  scenario 'uploads an invalid inventory file with ungrouped datasets' do
    spreadsheet_file = File.new("#{Rails.root}/spec/fixtures/files/inventario_general_de_datos-error_no_agrupados.xlsx")
    inventory = create(:inventory, organization: @user.organization, spreadsheet_file: spreadsheet_file)
    InventoryXLSXParserWorker.new.perform(inventory.id)
    visit inventory_path(inventory)

    expect(page).to have_text('Se encontraron las siguientes observaciones en el archivo de Inventario de Datos:')
    expect(page).to have_text(' Todos los recursos de un mismo conjunto de datos deben de estar agrupados.')
  end

  scenario 'sees new inventory form when no inventory has been uploaded' do
    visit inventories_path
    expect(page).to have_text('Sube el inventario de datos')
    expect(page).to have_text('Selecciona el archivo')
    expect(page).to have_text('Selecciona el archivo de la Minuta de Autorización del Grupo de Trabajo')
    find_button('Subir inventario')
  end


end
