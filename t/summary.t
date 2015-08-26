use Test::Most;
use Rex::Config;
use Rex::Commands;
use Rex::Commands::Run;
use Rex::Transaction;

$::QUIET = 1;

subtest "distributor => 'Base'" => sub {

    subtest 'exec_autodie => 0' => sub {
        Rex::Config->set_exec_autodie(0);
        Rex::Config->set_distributor('Base');
        test_summary(
            task0 => {server => '<local>', task => 'task0', exit_code => 1},
            task1 => {server => '<local>', task => 'task1', exit_code => 0},
            task2 => {server => '<local>', task => 'task2', exit_code => 0},
            task3 => {server => '<local>', task => 'task3', exit_code => 1},
            task4 => {server => '<local>', task => 'task4', exit_code => 1},
        );
    };

    subtest 'exec_autodie => 1' => sub {
        Rex::Config->set_exec_autodie(1);
        Rex::Config->set_distributor('Base');
        test_summary(
            task0 => {server => '<local>', task => 'task0', exit_code => 1},
            task1 => {server => '<local>', task => 'task1', exit_code => 2},
            task2 => {server => '<local>', task => 'task2', exit_code => 0},
            task3 => {server => '<local>', task => 'task3', exit_code => 1},
            task4 => {server => '<local>', task => 'task4', exit_code => 1},
        );
    };
};

subtest "distributor => 'Parallel_ForkManager'" => sub {
    subtest 'exec_autodie => 0' => sub {
        Rex::Config->set_exec_autodie(0);
        Rex::Config->set_distributor('Parallel_ForkManager');
        test_summary(
            task0 => {server => '<local>', task => 'task0', exit_code => 1},
            task1 => {server => '<local>', task => 'task1', exit_code => 0},
            task2 => {server => '<local>', task => 'task2', exit_code => 0},
            task3 => {server => '<local>', task => 'task3', exit_code => 1},
            task4 => {server => '<local>', task => 'task4', exit_code => 1},
        );
    };

    subtest 'exec_autodie => 1' => sub {
        Rex::Config->set_exec_autodie(1);
        Rex::Config->set_distributor('Parallel_ForkManager');
        test_summary(
            task0 => {server => '<local>', task => 'task0', exit_code => 1},
            task1 => {server => '<local>', task => 'task1', exit_code => 2},
            task2 => {server => '<local>', task => 'task2', exit_code => 0},
            task3 => {server => '<local>', task => 'task3', exit_code => 1},
            task4 => {server => '<local>', task => 'task4', exit_code => 1},
        );
    };
};

done_testing();

sub create_tasks {
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

    desc "desc 3";
    task "task3" => sub { 
        die "boop";
    };

    desc "desc 4";
    task "task4" => sub { 
        transaction {
            do_task qw/task3/;
        };
    };
}

sub test_summary {
    my (%expected) = @_;

    $Rex::TaskList::task_list = undef;

    create_tasks();

    my @summary;
    my @expected_summary;
    my $test_description;

    for my $task_name (Rex::TaskList->create->get_tasks) {
        Rex::TaskList->create->run($task_name);
        @summary = Rex::TaskList->create->get_summary;

        push @expected_summary, $expected{$task_name};

        $test_description = $expected{$task_name}->{exit_code} == 0
            ? "$task_name succeeded"
            : "$task_name failed";

        cmp_deeply \@summary, \@expected_summary, $test_description;
    }

    CORE::unlink("vars.db")      if -f "vars.db";
    CORE::unlink("vars.db.lock") if -f "vars.db.lock";
}
