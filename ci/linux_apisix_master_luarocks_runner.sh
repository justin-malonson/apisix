#!/usr/bin/env bash
#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

. ./ci/common.sh

do_install() {
    linux_get_dependencies

    export_or_prefix

    ./ci/linux-install-openresty.sh
    ./utils/linux-install-luarocks.sh
    ./ci/linux-install-etcd-client.sh
}

script() {
    export_or_prefix
    openresty -V

    sudo rm -rf /usr/local/apisix

    # run the test case in an empty folder
    mkdir tmp && cd tmp
    cp -r ../utils ./

    # install rust
    install_rust

    # install APISIX by luarocks
    luarocks install $APISIX_MAIN > build.log 2>&1 || (cat build.log && exit 1)
    cp ../bin/apisix /usr/local/bin/apisix

    # show install files
    luarocks show apisix

    sudo PATH=$PATH apisix help
    sudo PATH=$PATH apisix init
    sudo PATH=$PATH apisix start
    sudo PATH=$PATH apisix quit
    for i in {1..10}
    do
        if [ ! -f /usr/local/apisix/logs/nginx.pid ];then
            break
        fi
        sleep 0.3
    done
    sudo PATH=$PATH apisix start
    sudo PATH=$PATH apisix stop

    # apisix cli test
    # todo: need a more stable way

    grep '\[error\]' /usr/local/apisix/logs/error.log > /tmp/error.log | true
    if [ -s /tmp/error.log ]; then
        echo "=====found error log====="
        cat /usr/local/apisix/logs/error.log
        exit 1
    fi
}

case_opt=$1
shift

case ${case_opt} in
do_install)
    do_install "$@"
    ;;
script)
    script "$@"
    ;;
esac
