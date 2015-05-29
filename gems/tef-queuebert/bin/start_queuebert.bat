@echo off
title TEF Queuebert
if NOT DEFINED BUNDLE_MODE set BUNDLE_MODE=dev
if NOT DEFINED TEF_AMQP_URL_DEV set TEF_AMQP_URL_DEV=amqp://localhost:5672
if NOT DEFINED TEF_QUEUEBERT_SEARCH_ROOT set TEF_QUEUEBERT_SEARCH_ROOT=/projects
call bundle exec ruby bin\start_tef_queuebert
