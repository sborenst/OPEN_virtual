#!/bin/bash

SCRIPT_DIR=$(cd -P -- "$(dirname -- "$0")" && pwd -P)

export JBOSS_PORT_OFFSET=300
export RHSSO_HOME={{rhsso_install_dir}}
export RHSSO_ROOT=rhsso
export MYSQL_RHSSO_SCHEMA={{rhsso_mysql_schema}}

{{install_script_dir}}/{{rhsso_install_script_dir}}/{{rhsso_install_script}}