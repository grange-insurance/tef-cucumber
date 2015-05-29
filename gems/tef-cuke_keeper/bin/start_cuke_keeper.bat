@echo off
title TEF Cuke Keeper
if NOT DEFINED BUNDLE_MODE set BUNDLE_MODE=dev
if NOT DEFINED TEF_AMQP_URL_DEV set TEF_AMQP_URL_DEV=amqp://localhost:5672
call bundle exec ruby bin\start_tef_cuke_keeper
