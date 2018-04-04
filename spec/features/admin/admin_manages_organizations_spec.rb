require 'spec_helper'
require 'sidekiq/testing'

feature Admin, 'manages organizations:' do
  background do
    @admin = create(:super_user)
    given_logged_in_as(@admin)
  end

  scenario "sees organizations menu" do
    visit "/admin"
    expect(page).to have_link "Ver Organizaciones"
    click_on "Ver Organizaciones"
    expect(current_path).to eq(admin_organizations_path)
  end

  scenario "can create an new organization", js: true, skip: true do
    organization = FactoryGirl.build(:organization, :federal)
    visit "/admin/organizations"
    click_on 'Crear Organización'

    expect(current_path).to eq(new_admin_organization_path)
    fill_in('Nombre', with: organization.title)
    fill_in('Descripción', with: organization.description)
    fill_in('Sitio Web', with: organization.landing_page)
    select(organization.gov_type_i18n, from: 'organization_gov_type')
    click_on 'Guardar'

    sees_success_message "La organización se creó exitosamente."
    expect(current_path).to eq(admin_organizations_path)
    expect(page).to have_text(organization.title)
    expect(page).to have_text('Federal')
  end

  scenario "can edit an organization", js: true, skip: true do
    organization = FactoryGirl.create(:organization)
    new_attributes = FactoryGirl.attributes_for(:organization)
    visit "/admin/organizations"

    page.find("#organization_#{organization.id}").click
    click_on 'Editar'

    expect(current_path).to eq(edit_admin_organization_path(organization))
    fill_in('Nombre', with: new_attributes[:title])
    fill_in('Descripción', with: new_attributes[:description])
    fill_in('Sitio Web', with: new_attributes[:landing_page])
    select('Federal', from: 'organization_gov_type')
    click_on 'Guardar'

    organization.reload
    sees_success_message 'Se ha actualizado la organización exitosamente.'
    expect(current_path).to eq(admin_organizations_path)
    expect(page).to have_text(organization.title)
    expect(page).to have_text('Federal')
  end

  scenario 'can edit an organization', js: true, skip: true do
    organization  = FactoryGirl.create(:organization)
    administrator = FactoryGirl.create(:user, organization: organization)
    liaison = FactoryGirl.create(:user, organization: organization)

    visit '/admin/organizations'

    page.find("#organization_#{organization.id}").click
    click_on 'Editar'

    expect(current_path).to eq(edit_admin_organization_path(organization))

    select(administrator.name, from: 'organization_administrator_attributes_user_id')
    select(liaison.name, from: 'organization_liaison_attributes_user_id')

    click_on 'Guardar'

    organization.reload
    sees_success_message 'Se ha actualizado la organización exitosamente.'
    expect(current_path).to eq(admin_organizations_path)

    expect(organization.administrator.user.name).to eq(administrator.name)
    expect(organization.liaison.user.name).to eq(liaison.name)
  end

  scenario "can edit an organization gov_type", js: true, skip: true do
    organization =  FactoryGirl.create(:organization)
    visit "/admin/organizations"

    page.find("#organization_#{organization.id}_gov_type").click
    click_on 'Cambiar a Estatal'

    sees_success_message 'Se ha actualizado la organización exitosamente.'
    expect(current_path).to eq(admin_organizations_path)
    expect(page).to have_text(organization.title)
    expect(page).to have_text('Estatal')
  end

  scenario "can add a sector", js: true, skip: true do
    create(:sector, title: 'Educación')
    organization = FactoryGirl.create(:organization)
    new_attributes = FactoryGirl.attributes_for(:organization)
    visit "/admin/organizations"

    page.find("#organization_#{organization.id}").click
    click_on 'Editar'

    expect(current_path).to eq(edit_admin_organization_path(organization))
    click_on 'Agregar un sector'
    expect(page).to have_text('Eliminar sector')

    click_on 'Guardar'

    organization.reload
    sees_success_message 'Se ha actualizado la organización exitosamente.'
    expect(organization.sectors.count).to eq(1)
  end

  scenario "can delete a sector", js: true, skip: true do
    create(:sector, title: 'Educación')
    organization = FactoryGirl.create(:organization)
    new_attributes = FactoryGirl.attributes_for(:organization)

    visit "/admin/organizations"
    page.find("#organization_#{organization.id}").click
    click_on 'Editar'

    expect(current_path).to eq(edit_admin_organization_path(organization))
    click_on 'Agregar un sector'
    click_on 'Guardar'
    sees_success_message 'Se ha actualizado la organización exitosamente.'

    visit "/admin/organizations"
    page.find("#organization_#{organization.id}").click
    click_on 'Editar'

    expect(current_path).to eq(edit_admin_organization_path(organization))
    click_on 'Eliminar sector'
    click_on 'Guardar'

    organization.reload
    sees_success_message 'Se ha actualizado la organización exitosamente.'
    expect(organization.sectors.count).to eq(0)
  end
end
