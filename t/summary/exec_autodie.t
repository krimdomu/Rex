use Test::Most;
use Rex::Commands;
use Rex::Commands::Run;

Rex::Config->set_exec_autodie(1);

$::QUIET = 1;

desc "desc 0";
task "task0" => sub {
  die "bork0";
};

desc "desc 1";
task "task1" => sub { 
    run "ls asdfxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx";
};

desc "desc 2";
task "task2" => sub { 
    run "ls";
};


my @summary;
cleanup();

Rex::TaskList->create->run("task0");
@summary = Rex::TaskList->create->get_summary();
cmp_deeply
    \@summary,
    [{server => '<local>', task => 'task0', exit_code => 1}],
    'task failed';

Rex::TaskList->create->run("task1");
@summary = Rex::TaskList->create->get_summary();
cmp_deeply 
    \@summary,
    [{server => '<local>', task => 'task0', exit_code => 1},
     {server => '<local>', task => 'task1', exit_code => 2}],
    'task failed';

Rex::TaskList->create->run("task2");
@summary = Rex::TaskList->create->get_summary();
cmp_deeply
    \@summary,
    [{server => '<local>', task => 'task0', exit_code => 1},
     {server => '<local>', task => 'task1', exit_code => 2},
     {server => '<local>', task => 'task2', exit_code => 0}],
    'task succeeded';

cleanup();
done_testing();

sub cleanup {
    CORE::unlink("vars.db")      if -f "vars.db";
    CORE::unlink("vars.db.lock") if -f "vars.db.lock";
}
