#!/bin/bash

#############################################################################################################

# 安装 redis-trib.rb 的依赖
gem install --local /rdoc.gem 2>/dev/null 1>&2
gem install --local /redis.gem 2>/dev/null 1>&2
rm -f /rdoc.gem
rm -f /redis.gem

