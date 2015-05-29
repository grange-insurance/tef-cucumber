#!/bin/bash
if [ -z ${BUNDLE_MODE+x} ]; then
    echo "BUNDLE_MODE is unset, defaulting to 'dev'"
    export BUNDLE_MODE=dev
else
    echo "BUNDLE_MODE is set to '$BUNDLE_MODE'"
fi

if [ -z ${TEF_ENV+x} ]; then
    echo "TEF_ENV is unset, defaulting to 'dev'"
    export TEF_ENV=dev
else
    echo "TEF_ENV is set to '$TEF_ENV'";
fi

if [ -z ${TEF_QUEUEBERT_SEARCH_ROOT+x} ]; then
    echo "TEF_QUEUEBERT_SEARCH_ROOT is unset exiting";
    exit 1
else
    echo "TEF_QUEUEBERT_SEARCH_ROOT is set to '$TEF_QUEUEBERT_SEARCH_ROOT'";
fi

amqp_var=TEF_AMQP_URL"_"${TEF_ENV^^}
eval var=\$$amqp_var

if [ -z "$var" ]; then
    echo "TEF_AMQP_URL_${TEF_ENV^^} is unset defaulting to localhost";
    export TEF_AMQP_URL_${TEF_ENV^^}=amqp://localhost:5672
else
    echo "TEF_AMQP_URL_${TEF_ENV^^} is set to '$var'";
fi


DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
app="$DIR/start_tef_queuebert"
echo launching $app
bundle exec ruby  $app
