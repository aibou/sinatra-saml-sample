require 'sinatra'
require 'ruby-saml'

app_id = YOUR_APP_ID
idp_cert = <<-EOS
###### COPY Certificate from OneLogin
EOS

settings = OneLogin::RubySaml::Settings.new

settings.idp_entity_id = "https://app.onelogin.com/saml/metadata/#{app_id}"
settings.idp_sso_target_url = "https://app.onelogin.com/trust/saml2/http-post/sso/#{app_id}"
settings.idp_slo_target_url = "https://app.onelogin.com/trust/saml2/http-redirect/slo/#{app_id}"
settings.idp_cert = idp_cert
settings.name_identifier_format = "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress"

enable :sessions

get '/' do
  <<-EOS
Your name_id is #{session[:name_id]} <br/>
<a href="http://localhost:3000/login">http://localhost:3000/login</a>
EOS
end

get '/login' do
  request = OneLogin::RubySaml::Authrequest.new
  redirect request.create(settings), 302
end

post '/recipient' do
  response = OneLogin::RubySaml::Response.new(params[:SAMLResponse], settings: settings)
  if response.is_valid?
    session[:name_id] = response.name_id
    session[:attributes] = response.attributes
    "Login succeeded. your name_id is #{response.name_id}"
  else
    "Login invalid"
  end
end

get '/metadata' do
  metadata = OneLogin::RubySaml::Metadata.new
  "#{metadata.generate(settings, true)}"
end

get '/logout' do
  session.clear
end

