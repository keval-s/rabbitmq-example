#!/usr/bin/env bash

DEFAULT_MANAGEMENT_BASE_URL=http://localhost:15672
DEFAULT_MANAGEMENT_ADMIN_USER=guest
DEFAULT_MANAGEMENT_ADMIN_PWD=guest
MANAGEMENT_BASE_URL=${DEFAULT_MANAGEMENT_BASE_URL}
PROVIDE_USER_CREDENTIALS=false
MANAGEMENT_ADMIN_USER=${DEFAULT_MANAGEMENT_ADMIN_USER}
MANAGEMENT_ADMIN_PWD=${DEFAULT_MANAGEMENT_ADMIN_PWD}

VHOSTS_CSV_FILE="data/vhosts.csv"
EXCHANGES_CSV_FILE="data/exchanges.csv"
QUEUES_CSV_FILE="data/queues.csv"
QUEUE_BINDINGS_CSV_FILE="data/queue_bindings.csv"
USERS_CSV_FILE="data/users.csv"
USER_PERMISSIONS_CSV_FILE="data/user_permissions.csv"

# Verifies the RabbitMQ management URL and credentials
#
# Examples
#
#   verifyManagementURLAndCredentials
function verifyManagementURLAndCredentials() {
  printf "Verifying management URL and credentials at '%s' with user '%s'...\n" "${MANAGEMENT_BASE_URL}/api/whoami" "${MANAGEMENT_ADMIN_USER}"
  local result
  result=$(curl -f -s -S -w "%{http_code}" -u "${MANAGEMENT_ADMIN_USER}":"${MANAGEMENT_ADMIN_PWD}" -H "content-type:application/json" "${MANAGEMENT_BASE_URL}/api/whoami")
  local status=${result: -3}
  if [[ "${status}" != "200" ]]; then
    printf "ERROR [line %s]: Verification for management URL and user failed\n\n" "${LINENO}" 1>&2
    return 1
  else
    printf "Management URL and credentials verified!\n\n"
    return 0
  fi
}

# Creates a virtual host if it doesn't already exist on the RabbitMQ broker.
#
# $1 - Name of virtual host (Required - cannot be blank)
#
# Examples
#
#   createVirtualHost "foo"
function createVirtualHost() {
  printf "Creating virtual host '%s'...\n" "$1"
  if [[ -n "$1" ]]; then
    local vhost=$1
    local result
    result=$(curl -f -s -S -w "%{http_code}" -u "${MANAGEMENT_ADMIN_USER}":"${MANAGEMENT_ADMIN_PWD}" -H "content-type:application/json" \
      -XPUT "${MANAGEMENT_BASE_URL}/api/vhosts/${vhost}")
    local status=${result: -3}
    if [[ "${status}" == "201" ]]; then
      printf "Virtual host successfully created!\n\n"
      return 0
    elif [[ "${status}" == "204" ]]; then
      printf "Virtual host already exists!\n\n"
      return 0
    else
      printf "ERROR [line %s]: The API request to create virtual host returned an error code\n\n" "${LINENO}" 1>&2
      return 1
    fi
  else
    printf "ERROR [line %s]: createVirtualHost() requires an input parameter. See function documentation for more details\n\n" "${LINENO}" 1>&2
    return 1
  fi
}

# Creates an exchange in the specified virtual host with the specified properties.
#
# $1 - Name of virtual host to create exchange in (Required - cannot be blank)
# $2 - Name of exchange to create (Required - cannot be blank)
# $3 - Exchange properties (Required - cannot be blank)
#
# Examples
#
#   createExchange "foo" "bar.exchange" '{"type":"direct","auto_delete":false,"durable":true,"internal":false,"arguments":{}}'
function createExchange() {
  printf "Creating exchange '%s' in virtual host '%s' with properties '%s'...\n" "$2" "$1" "$3"
  local vhost
  if [[ -n "$1" ]]; then
    vhost=$1
  else
    printf "ERROR [line %s]: createExchange() invalid argument. See function documentation for more details\n\n" "${LINENO}" 1>&2
    return 1
  fi

  local exchange
  if [[ -n "$2" ]]; then
    exchange=$2
  else
    printf "ERROR [line %s]: createExchange() invalid argument. See function documentation for more details\n\n" "${LINENO}" 1>&2
    return 1
  fi

  local properties
  if [[ -n "$3" ]]; then
    properties=$3
  else
    printf "ERROR [line %s]: createExchange() invalid argument. See function documentation for more details\n\n" "${LINENO}" 1>&2
    return 1
  fi

  local result
  result=$(curl -f -s -S -w "%{http_code}" -u "${MANAGEMENT_ADMIN_USER}":"${MANAGEMENT_ADMIN_PWD}" -H "content-type:application/json" \
    -XPUT "${MANAGEMENT_BASE_URL}/api/exchanges/${vhost}/${exchange}" -d "${properties}")
  local status=${result: -3}
  if [[ "${status}" == "201" ]]; then
    printf "Exchange successfully created!\n\n"
    return 0
  elif [[ "${status}" == "204" ]]; then
    printf "Exchange already exists!\n\n"
    return 0
  else
    printf "ERROR [line %s]: The API request to create exchange returned an error code '%s'\n\n" "${LINENO}" "${status}" 1>&2
    return 1
  fi

}

# Creates a queue in the specified virtual host with the specified properties.
#
# $1 - Name of virtual host to create queue in (Required - cannot be blank)
# $2 - Name of queue to create (Required - cannot be blank)
# $3 - Queue properties (Required - cannot be blank)
#
# Examples
#
#   createQueue "foo" "input.q" '{"auto_delete":false,"durable":true,"arguments":{}}'
function createQueue() {
  printf "Creating queue '%s' in virtual host '%s' with properties '%s'...\n" "$2" "$1" "$3"
  local vhost
  if [[ -n "$1" ]]; then
    vhost=$1
  else
    printf "ERROR [line %s]: createQueue() invalid argument. See function documentation for more details\n\n" "${LINENO}" 1>&2
    return 1
  fi

  local queue
  if [[ -n "$2" ]]; then
    queue=$2
  else
    printf "ERROR [line %s]: createQueue() invalid argument. See function documentation for more details\n\n" "${LINENO}" 1>&2
    return 1
  fi

  local properties
  if [[ -n "$3" ]]; then
    properties=$3
  else
    printf "ERROR [line %s]: createQueue() invalid argument. See function documentation for more details\n\n" "${LINENO}" 1>&2
    return 1
  fi

  local result
  result=$(curl -f -s -S -w "%{http_code}" -u "${MANAGEMENT_ADMIN_USER}":"${MANAGEMENT_ADMIN_PWD}" -H "content-type:application/json" \
    -XPUT "${MANAGEMENT_BASE_URL}/api/queues/${vhost}/${queue}" -d "${properties}")
  local status=${result: -3}
  if [[ "${status}" == "201" ]]; then
    printf "Queue successfully created!\n\n"
    return 0
  elif [[ "${status}" == "204" ]]; then
    printf "Queue already exists!\n\n"
    return 0
  else
    printf "ERROR [line %s]: The API request to create queue returned an error code '%s'\n\n" "${LINENO}" "${status}" 1>&2
    return 1
  fi

}

# Creates a queue in the specified virtual host with the specified properties.
#
# $1 - Name of virtual host to create binding in (Required - cannot be blank)
# $2 - Name of queue to create binding for (Required - cannot be blank)
# $3 - Name of exchange to create binding for (Required - cannot be blank)
# $4 - Binding properties (Required - cannot be blank)
#
# Examples
#
#   createBinding "foo" "input.q" "bar.exchange" '{"routing_key":"my_routing_key","arguments":{}}'
function createBinding() {
  printf "Creating binding between queue '%s' and exchange '%s' in virtual host '%s' with properties '%s'...\n" "$2" "$3" "$1" "$4"
  local vhost
  if [[ -n "$1" ]]; then
    vhost=$1
  else
    printf "ERROR [line %s]: createBinding() invalid argument. See function documentation for more details\n\n" "${LINENO}" 1>&2
    return 1
  fi

  local queue
  if [[ -n "$2" ]]; then
    queue=$2
  else
    printf "ERROR [line %s]: createBinding() invalid argument. See function documentation for more details\n\n" "${LINENO}" 1>&2
    return 1
  fi

  local exchange
  if [[ -n "$3" ]]; then
    exchange=$3
  else
    printf "ERROR [line %s]: createBinding() invalid argument. See function documentation for more details\n\n" "${LINENO}" 1>&2
    return 1
  fi

  local properties
  if [[ -n "$4" ]]; then
    properties=$4
  else
    printf "ERROR [line %s]: createBinding() invalid argument. See function documentation for more details\n\n" "${LINENO}" 1>&2
    return 1
  fi

  local result
  result=$(curl -f -s -S -w "%{http_code}" -u "${MANAGEMENT_ADMIN_USER}":"${MANAGEMENT_ADMIN_PWD}" -H "content-type:application/json" \
    -XPOST "${MANAGEMENT_BASE_URL}/api/bindings/${vhost}/e/${exchange}/q/${queue}" -d "${properties}")
  local status=${result: -3}
  if [[ "${status}" == "201" ]]; then
    printf "Binding successfully created!\n\n"
    return 0
  else
    printf "ERROR [line %s]: The API request to create binding returned an error code '%s'\n\n" "${LINENO}" "${status}" 1>&2
    return 1
  fi

}

# Creates a policy in the specified virtual host.
#
# $1 - Name of virtual host to create policy in (Required - cannot be blank)
# $2 - Name of policy to create (Required - cannot be blank)
# $3 - Policy properties (Required - cannot be blank)
#
# Examples
#
#   createPolicy "foo" "input.policy" '{"pattern":"^input.", "definition": {"federation-upstream-set":"all"}, "priority":0, "apply-to": "all"}'
function createPolicy() {
  printf "Creating policy '%s' in virtual host '%s' with properties '%s'...\n" "$2" "$1" "$3"
  local vhost
  if [[ -n "$1" ]]; then
    vhost=$1
  else
    printf "ERROR [line %s]: createPolicy() invalid argument. See function documentation for more details\n\n" "${LINENO}" 1>&2
    return 1
  fi

  local policy
  if [[ -n "$2" ]]; then
    policy=$2
  else
    printf "ERROR [line %s]: createPolicy() invalid argument. See function documentation for more details\n\n" "${LINENO}" 1>&2
    return 1
  fi

  local properties
  if [[ -n "$3" ]]; then
    properties=$3
  else
    printf "ERROR [line %s]: createPolicy() invalid argument. See function documentation for more details\n\n" "${LINENO}" 1>&2
    return 1
  fi

  local result
  result=$(curl -f -s -S -w "%{http_code}" -u "${MANAGEMENT_ADMIN_USER}":"${MANAGEMENT_ADMIN_PWD}" -H "content-type:application/json" \
    -XPUT "${MANAGEMENT_BASE_URL}/api/policies/${vhost}/${policy}" -d "${properties}")
  local status=${result: -3}
  if [[ "${status}" == "201" ]]; then
    printf "Policy successfully created!\n\n"
    return 0
  elif [[ "${status}" == "204" ]]; then
    printf "Policy already exists!\n\n"
    return 0
  else
    printf "ERROR [line %s]: The API request to create binding returned an error code '%s'\n\n" "${LINENO}" "${status}" 1>&2
    return 1
  fi

}

# Creates a user.
#
# $1 - Name of user to create (Required - cannot be blank)
# $2 - User properties (Required - cannot be blank)
#
# Examples
#
#   createUser "user" '{"password_hash":"2lmoth8l4H0DViLaK9Fxi6l9ds8=", "tags":""}'
#   createUser "admin" '{"password_hash":"2lmoth8l4H0DViLaK9Fxi6l9ds8=", "tags":"administrator"}'
function createUser() {
  printf "Creating user '%s'...\n" "$1"
  local user
  if [[ -n "$1" ]]; then
    user=$1
  else
    printf "ERROR [line %s]: createUser() invalid argument. See function documentation for more details\n\n" "${LINENO}" 1>&2
    return 1
  fi

  local properties
  if [[ -n "$2" ]]; then
    properties=$2
  else
    printf "ERROR [line %s]: createUser() invalid argument. See function documentation for more details\n\n" "${LINENO}" 1>&2
    return 1
  fi

  local result
  result=$(curl -f -s -S -w "%{http_code}" -u "${MANAGEMENT_ADMIN_USER}":"${MANAGEMENT_ADMIN_PWD}" -H "content-type:application/json" \
    -XPUT "${MANAGEMENT_BASE_URL}/api/users/${user}" -d "${properties}")
  local status=${result: -3}
  if [[ "${status}" == "201" ]]; then
    printf "User successfully created!\n\n"
    return 0
  elif [[ "${status}" == "204" ]]; then
    printf "User already exists!\n\n"
    return 0
  else
    printf "ERROR [line %s]: The API request to create user returned an error code '%s'\n\n" "${LINENO}" "${status}" 1>&2
    return 1
  fi

}

# Creates a permission for a user in virtual host.
#
# $1 - Name of virtual host (Required - cannot be blank)
# $2 - Name of user to create permission for (Required - cannot be blank)
# $3 - Permission (Required - cannot be blank)
#
# Examples
#
#   createUserPermission "foo" "user" '{"configure":".*","write":".*","read":".*"}'
#   createUserPermission "foo" "user" '{"configure":"^$","write":"input\..+","read":"input\..+"}'
function createUserPermission() {
  printf "Creating permission '%s' for user '%s' in virtual host '%s'...\n" "$3" "$2" "$1"
  local vhost
  if [[ -n "$1" ]]; then
    vhost=$1
  else
    printf "ERROR [line %s]: createUserPermission() invalid argument. See function documentation for more details\n\n" "${LINENO}" 1>&2
    return 1
  fi

  local user
  if [[ -n "$2" ]]; then
    user=$2
  else
    printf "ERROR [line %s]: createUserPermission() invalid argument. See function documentation for more details\n\n" "${LINENO}" 1>&2
    return 1
  fi

  local permission
  if [[ -n "$3" ]]; then
    permission=$3
  else
    printf "ERROR [line %s]: createUserPermission() invalid argument. See function documentation for more details\n\n" "${LINENO}" 1>&2
    return 1
  fi

  local result
  result=$(curl -f -s -S -w "%{http_code}" -u "${MANAGEMENT_ADMIN_USER}":"${MANAGEMENT_ADMIN_PWD}" -H "content-type:application/json" \
    -XPUT "${MANAGEMENT_BASE_URL}/api/permissions/${vhost}/${user}" -d "${permission}")
  local status=${result: -3}
  if [[ "${status}" == "201" ]]; then
    printf "User permission successfully created!\n\n"
    return 0
  elif [[ "${status}" == "204" ]]; then
    printf "User permission already exists!\n\n"
    return 0
  else
    printf "ERROR [line %s]: The API request to create user permission returned an error code '%s'\n\n" "${LINENO}" "${status}" 1>&2
    return 1
  fi

}

# Will create a virtual host for each entry in the CSV file '${VHOSTS_CSV_FILE}' from the second line onwards.
# Last line in the CSV must be a new line.
#
# Examples
#
#   readVirtualHostsFromCSVFileAndCreate
function readVirtualHostsFromCSVFileAndCreate() {
  printf "Reading CSV file '%s' and creating virtual host(s)...\n" "${VHOSTS_CSV_FILE}"
  [ ! -f ${VHOSTS_CSV_FILE} ] && {
    printf "ERROR [line %s]: File not found: '%s'\n\n" "${LINENO}" "${VHOSTS_CSV_FILE}" 1>&2
    exit 1
  }
  while read -r vhost_name; do
    createVirtualHost "${vhost_name}" || return 1
  done < <(tail -n +2 "${VHOSTS_CSV_FILE}")
  return 0
}

# Will create an exchange for each entry in the CSV file '${EXCHANGES_CSV_FILE}' from the second line onwards.
# Last line in the CSV must be a new line.
#
# Examples
#
#   readExchangesFromCSVFileAndCreate
function readExchangesFromCSVFileAndCreate() {
  printf "Reading CSV file '%s' and creating exchange(s)...\n" "${EXCHANGES_CSV_FILE}"
  [ ! -f ${EXCHANGES_CSV_FILE} ] && {
    printf "ERROR [line %s]: File not found: '%s'\n\n" "${LINENO}" "${EXCHANGES_CSV_FILE}" 1>&2
    exit 1
  }
  local prv_ifs=${IFS}
  IFS=','
  while read -r vhost_name exchange_name exchange_properties; do
    createExchange "${vhost_name}" "${exchange_name}" "${exchange_properties}" || return 1
  done < <(tail -n +2 "${EXCHANGES_CSV_FILE}")
  IFS=${prv_ifs}
  return 0
}

# Will create a queue for each entry in the CSV file '${QUEUES_CSV_FILE}' from the second line onwards.
# Last line in the CSV must be a new line.
#
# Examples
#
#   readQueuesFromCSVFileAndCreate
function readQueuesFromCSVFileAndCreate() {
  printf "Reading CSV file '%s' and creating queue(s)...\n" "${QUEUES_CSV_FILE}"
  [ ! -f ${QUEUES_CSV_FILE} ] && {
    printf "ERROR [line %s]: File not found: '%s'\n\n" "${LINENO}" "${QUEUES_CSV_FILE}" 1>&2
    exit 1
  }
  local prv_ifs=${IFS}
  IFS=','
  while read -r vhost_name queue_name queue_properties; do
    createQueue "${vhost_name}" "${queue_name}" "${queue_properties}" || return 1
  done < <(tail -n +2 "${QUEUES_CSV_FILE}")
  IFS=${prv_ifs}
  return 0
}

# Will create a queue binding for each entry in the CSV file '${QUEUE_BINDINGS_CSV_FILE}' from the second line onwards.
# Last line in the CSV must be a new line.
#
# Examples
#
#   readQueueBindingsFromCSVFileAndCreate
function readQueueBindingsFromCSVFileAndCreate() {
  printf "Reading CSV file '%s' and creating queue binding(s)...\n" "${QUEUE_BINDINGS_CSV_FILE}"
  [ ! -f ${QUEUE_BINDINGS_CSV_FILE} ] && {
    printf "ERROR [line %s]: File not found: '%s'\n\n" "${LINENO}" "${QUEUE_BINDINGS_CSV_FILE}" 1>&2
    exit 1
  }
  local prv_ifs=${IFS}
  IFS=','
  while read -r vhost_name queue_name binding_exchange_name binding_properties; do
    createBinding "${vhost_name}" "${queue_name}" "${binding_exchange_name}" "${binding_properties}" || return 1
  done < <(tail -n +2 "${QUEUE_BINDINGS_CSV_FILE}")
  IFS=${prv_ifs}
  return 0
}

# Will create a user for each entry in the CSV file '${USERS_CSV_FILE}' from the second line onwards.
# Last line in the CSV must be a new line.
#
# Examples
#
#   readUsersFromCSVFileAndCreate
function readUsersFromCSVFileAndCreate() {
  printf "Reading CSV file '%s' and creating user(s)...\n" "${USERS_CSV_FILE}"
  [ ! -f ${USERS_CSV_FILE} ] && {
    printf "ERROR [line %s]: File not found: '%s'\n\n" "${LINENO}" "${USERS_CSV_FILE}" 1>&2
    exit 1
  }
  local prv_ifs=${IFS}
  IFS=','
  while read -r user_name user_properties; do
    createUser "${user_name}" "${user_properties}" || return 1
  done < <(tail -n +2 "${USERS_CSV_FILE}")
  IFS=${prv_ifs}
  return 0
}

# Will create a user permission for each entry in the CSV file '${USER_PERMISSIONS_CSV_FILE}' from the second line onwards.
# Last line in the CSV must be a new line.
#
# Examples
#
#   readUserPermissionsFromCSVFileAndCreate
function readUserPermissionsFromCSVFileAndCreate() {
  printf "Reading CSV file '%s' and creating user permission(s)...\n" "${USER_PERMISSIONS_CSV_FILE}"
  [ ! -f ${USER_PERMISSIONS_CSV_FILE} ] && {
    printf "ERROR [line %s]: File not found: '%s'\n\n" "${LINENO}" "${USER_PERMISSIONS_CSV_FILE}" 1>&2
    exit 1
  }
  local prv_ifs=${IFS}
  IFS=','
  while read -r vhost_name user_name user_permission; do
    createUserPermission "${vhost_name}" "${user_name}" "${user_permission}" || return 1
  done < <(tail -n +2 "${USER_PERMISSIONS_CSV_FILE}")
  IFS=${prv_ifs}
  return 0
}

################################
# Script execution starts here
################################

for i in "$@"; do
  case $i in
  -b=* | --baseurl=*)
    MANAGEMENT_BASE_URL="${i#*=}"
    shift
    ;;
  -u | --user)
    PROVIDE_USER_CREDENTIALS=true
    shift
    ;;
  *)
    # Unknown option
    echo "ERROR [line ${LINENO}]: An unrecognized argument '${i}' was passed to the script" 1>&2
    exit 1
    ;;
  esac
done

if [ "${PROVIDE_USER_CREDENTIALS}" = true ]; then
  read -rp 'Enter management admin username: ' MANAGEMENT_ADMIN_USER
  read -rsp 'Enter management admin password (will be hidden): ' MANAGEMENT_ADMIN_PWD
fi
printf "\n"

verifyManagementURLAndCredentials || exit 1
readVirtualHostsFromCSVFileAndCreate || exit 1
readExchangesFromCSVFileAndCreate || exit 1
readQueuesFromCSVFileAndCreate || exit 1
readQueueBindingsFromCSVFileAndCreate || exit 1
readUsersFromCSVFileAndCreate || exit 1
readUserPermissionsFromCSVFileAndCreate || exit 1
