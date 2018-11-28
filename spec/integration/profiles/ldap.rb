# frozen_string_literal: true

require "net/ldap"
require_relative "shared"

clean_db!
create_registry!

##
# Create bot and DB user.

User.create!(
  username: "pfabra",
  password: "giecftw1918",
  email:    "pfabra@iec.cat",
  bot:      true
)
User.create!(username: "noller", password: "lapapallona", email: "noller@renaixenca.cat")

##
# Set parameters and initialize LDAP object.

params = { host: APP_CONFIG["ldap"]["hostname"], port: APP_CONFIG["ldap"]["port"] }

# Fill authentication details.
if APP_CONFIG.enabled?("ldap.authentication")
  params[:auth] = {
    method:   :simple,
    username: APP_CONFIG["ldap"]["authentication"]["bind_dn"],
    password: APP_CONFIG["ldap"]["authentication"]["password"]
  }
end

# Fill TLS options with the given env. variables or assume defaults.
if APP_CONFIG["ldap"]["encryption"]["method"].present?
  params[:encryption] = { method: APP_CONFIG["ldap"]["encryption"]["method"].to_sym }

  if APP_CONFIG["ldap"]["encryption"]["options"]["ca_file"].present?
    params[:encryption][:tls_options] = {
      ca_file:     APP_CONFIG["ldap"]["encryption"]["options"]["ca_file"],
      ssl_version: APP_CONFIG["ldap"]["encryption"]["options"]["ssl_version"]
    }
  else
    params[:encryption][:tls_options] = OpenSSL::SSL::SSLContext::DEFAULT_PARAMS
  end
end

ldap = Net::LDAP.new(params)

##
# Add test users and admins group.

# Prints the last operation result, and if it's not ok (neither 0 nor 68 (entry
# already exists)), then it will raise an exception.
def handle_ldap_result!(ldap, params)
  puts "#{ldap.get_operation_result.message} (code #{ldap.get_operation_result.code})."
  code = ldap.get_operation_result.code
  return if code.zero? || code == 68

  raise StandardError, "Parameters used: #{params}"
end

ldap.add(
  dn:         "uid=jverdaguer,dc=example,dc=org",
  attributes: {
    cn:           "Jacint Verdaguer",
    givenName:    "Jacint",
    sn:           "Verdaguer",
    displayName:  "Jacint Verdaguer",
    objectclass:  %w[top inetorgperson],
    userPassword: Net::LDAP::Password.generate(:md5, "folgueroles"),
    mail:         "jverdaguer@renaixenca.cat"
  }
)
handle_ldap_result!(ldap, params)

ldap.add(
  dn:         "dc=admins,dc=example,dc=org",
  attributes: { dc: "admins", objectclass: %w[top domain] }
)
handle_ldap_result!(ldap, params)

ldap.add(
  dn:         "uid=calbert,dc=admins,dc=example,dc=org",
  attributes: {
    cn:           "Caterina Albert",
    givenName:    "Caterina",
    sn:           "Albert",
    displayName:  "Caterina Albert",
    objectclass:  %w[top inetorgperson],
    userPassword: Net::LDAP::Password.generate(:md5, "victorcatala"),
    mail:         "calbert@renaixenca.cat"
  }
)
handle_ldap_result!(ldap, params)
