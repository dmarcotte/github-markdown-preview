# ensure celluloid plays nice with minitest.  See https://github.com/celluloid/celluloid/pull/162
require 'celluloid/test.rb'
Celluloid.boot
