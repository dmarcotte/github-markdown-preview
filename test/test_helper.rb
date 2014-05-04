# celluloid (used by guard/listen) needs to be told we're testing so that one test's teardown
# doesn't accidentally shut down the next test's celluloid setup.
# See https://github.com/celluloid/celluloid/blob/87592f9fbba99c7228a22618c33e88265c8a0516/lib/celluloid.rb#L513
$CELLULOID_TEST = true