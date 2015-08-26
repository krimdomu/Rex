use Test::Most;
use Rex::Commands;
use Rex::Commands::Run;

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

subtest 'with Rex::TaskList::ParallelForkManager' => sub {
    Rex::Config->set_exec_autodie(0);
    Rex::Config->set_distributor('Parallel_ForkManager');
    run_tests();
};

subtest 'with Rex::TaskList::Base' => sub {
    Rex::Config->set_exec_autodie(0);
    Rex::Config->set_distributor('Base');
    run_tests();
};

done_testing();

sub cleanup {
    CORE::unlink("vars.db")      if -f "vars.db";
    CORE::unlink("vars.db.lock") if -f "vars.db.lock";
}

sub run_tests {
    my @summary;
    my @tasks = Rex::TaskList->create->get_all_tasks();
    use DDP; p @tasks;

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
        {server => '<local>', task => 'task1', exit_code => 0}],
        'task succeeded';

    Rex::TaskList->create->run("task2");
    @summary = Rex::TaskList->create->get_summary();
    cmp_deeply
        \@summary,
        [{server => '<local>', task => 'task0', exit_code => 1},
        {server => '<local>', task => 'task1', exit_code => 0},
        {server => '<local>', task => 'task2', exit_code => 0}],
        'task succeeded';

    cleanup();
}
