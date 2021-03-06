#! /usr/bin/perl

# Copyright (C) 2018 SUSE LLC
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

BEGIN {
    unshift @INC, 'lib';
}

use FindBin;
use lib "$FindBin::Bin/lib";
use Mojo::Base -strict;
use Test::More;
use Test::Mojo;
use Test::Warnings;
use OpenQA::Test::Case;
use OpenQA::Schema::JobGroupDefaults;

# init test case
my $test_case = OpenQA::Test::Case->new;
$test_case->init_data;
my $t = Test::Mojo->new('OpenQA::WebAPI');

# get resultsets
my $db            = $t->app->db;
my $job_groups    = $db->resultset('JobGroups');
my $parent_groups = $db->resultset('JobGroupParents');

# create new parent group
my $new_parent_group_id = $parent_groups->create({name => 'new parent group'})->id;
my $new_parent_group    = $parent_groups->find($new_parent_group_id);
ok($new_parent_group, 'create new parent group');

# create new job group
my $new_job_group_id = $job_groups->create({name => 'new job group'})->id;
my $new_job_group    = $job_groups->find($new_job_group_id);
ok($new_job_group, 'create new job group');

subtest 'defaults of parent group' => sub {
    is($new_parent_group->default_size_limit_gb,     OpenQA::Schema::JobGroupDefaults::SIZE_LIMIT_GB);
    is($new_parent_group->default_keep_logs_in_days, OpenQA::Schema::JobGroupDefaults::KEEP_LOGS_IN_DAYS);
    is(
        $new_parent_group->default_keep_important_logs_in_days,
        OpenQA::Schema::JobGroupDefaults::KEEP_IMPORTANT_LOGS_IN_DAYS
    );
    is($new_parent_group->default_keep_results_in_days, OpenQA::Schema::JobGroupDefaults::KEEP_RESULTS_IN_DAYS);
    is(
        $new_parent_group->default_keep_important_results_in_days,
        OpenQA::Schema::JobGroupDefaults::KEEP_IMPORTANT_RESULTS_IN_DAYS
    );
    is($new_parent_group->default_priority, OpenQA::Schema::JobGroupDefaults::PRIORITY);
};

subtest 'defaults of group without parent' => sub {
    is($new_job_group->size_limit_gb,               OpenQA::Schema::JobGroupDefaults::SIZE_LIMIT_GB);
    is($new_job_group->keep_logs_in_days,           OpenQA::Schema::JobGroupDefaults::KEEP_LOGS_IN_DAYS);
    is($new_job_group->keep_important_logs_in_days, OpenQA::Schema::JobGroupDefaults::KEEP_IMPORTANT_LOGS_IN_DAYS);
    is($new_job_group->keep_results_in_days,        OpenQA::Schema::JobGroupDefaults::KEEP_RESULTS_IN_DAYS);
    is($new_job_group->keep_important_results_in_days,
        OpenQA::Schema::JobGroupDefaults::KEEP_IMPORTANT_RESULTS_IN_DAYS);
    is($new_job_group->default_priority, OpenQA::Schema::JobGroupDefaults::PRIORITY);
};

subtest 'overrideing defaults in settings affects groups' => sub {
    my $config = $t->app->config->{default_group_limits};
    my @fields
      = qw(asset_size_limit log_storage_duration important_log_storage_duration result_storage_duration important_result_storage_duration);
    $config->{$_} += 1000 for (@fields);

    subtest 'defaults for parent group overridden' => sub {
        is($new_parent_group->default_size_limit_gb,     OpenQA::Schema::JobGroupDefaults::SIZE_LIMIT_GB + 1000);
        is($new_parent_group->default_keep_logs_in_days, OpenQA::Schema::JobGroupDefaults::KEEP_LOGS_IN_DAYS + 1000);
        is(
            $new_parent_group->default_keep_important_logs_in_days,
            OpenQA::Schema::JobGroupDefaults::KEEP_IMPORTANT_LOGS_IN_DAYS + 1000
        );
        is($new_parent_group->default_keep_results_in_days,
            OpenQA::Schema::JobGroupDefaults::KEEP_RESULTS_IN_DAYS + 1000);
        is(
            $new_parent_group->default_keep_important_results_in_days,
            OpenQA::Schema::JobGroupDefaults::KEEP_IMPORTANT_RESULTS_IN_DAYS + 1000
        );
    };

    subtest 'defaults for job group overridden' => sub {
        is($new_job_group->size_limit_gb,     OpenQA::Schema::JobGroupDefaults::SIZE_LIMIT_GB + 1000);
        is($new_job_group->keep_logs_in_days, OpenQA::Schema::JobGroupDefaults::KEEP_LOGS_IN_DAYS + 1000);
        is($new_job_group->keep_important_logs_in_days,
            OpenQA::Schema::JobGroupDefaults::KEEP_IMPORTANT_LOGS_IN_DAYS + 1000);
        is($new_job_group->keep_results_in_days, OpenQA::Schema::JobGroupDefaults::KEEP_RESULTS_IN_DAYS + 1000);
        is($new_job_group->keep_important_results_in_days,
            OpenQA::Schema::JobGroupDefaults::KEEP_IMPORTANT_RESULTS_IN_DAYS + 1000);
    };
};

subtest 'defaults overridden on parent group level' => sub {
    my @columns
      = qw(default_size_limit_gb default_keep_logs_in_days default_keep_important_logs_in_days default_keep_results_in_days default_keep_important_results_in_days default_priority);
    for my $column (@columns) {
        $new_parent_group->update({$column => $new_parent_group->$column + 1000});
    }

    is($new_parent_group->default_size_limit_gb,     OpenQA::Schema::JobGroupDefaults::SIZE_LIMIT_GB + 2000);
    is($new_parent_group->default_keep_logs_in_days, OpenQA::Schema::JobGroupDefaults::KEEP_LOGS_IN_DAYS + 2000);
    is(
        $new_parent_group->default_keep_important_logs_in_days,
        OpenQA::Schema::JobGroupDefaults::KEEP_IMPORTANT_LOGS_IN_DAYS + 2000
    );
    is($new_parent_group->default_keep_results_in_days, OpenQA::Schema::JobGroupDefaults::KEEP_RESULTS_IN_DAYS + 2000);
    is(
        $new_parent_group->default_keep_important_results_in_days,
        OpenQA::Schema::JobGroupDefaults::KEEP_IMPORTANT_RESULTS_IN_DAYS + 2000
    );
    is($new_parent_group->default_priority, OpenQA::Schema::JobGroupDefaults::PRIORITY + 1000);

    # note: prio is just + 1000 (and not + 2000) because in contrast to the other values the default wasn't changed
    # in previous subtest 'overrideing defaults in settings affects groups'
};

subtest 'job group properties inherited from parent group' => sub {
    $new_job_group->update({parent_id => $new_parent_group_id});

    is($new_job_group->size_limit_gb,     OpenQA::Schema::JobGroupDefaults::SIZE_LIMIT_GB + 2000);
    is($new_job_group->keep_logs_in_days, OpenQA::Schema::JobGroupDefaults::KEEP_LOGS_IN_DAYS + 2000);
    is($new_job_group->keep_important_logs_in_days,
        OpenQA::Schema::JobGroupDefaults::KEEP_IMPORTANT_LOGS_IN_DAYS + 2000);
    is($new_job_group->keep_results_in_days, OpenQA::Schema::JobGroupDefaults::KEEP_RESULTS_IN_DAYS + 2000);
    is($new_job_group->keep_important_results_in_days,
        OpenQA::Schema::JobGroupDefaults::KEEP_IMPORTANT_RESULTS_IN_DAYS + 2000);
    is($new_job_group->default_priority, OpenQA::Schema::JobGroupDefaults::PRIORITY + 1000);
};

subtest 'inherited job group properties overridden' => sub {
    my @columns
      = qw(size_limit_gb keep_logs_in_days keep_important_logs_in_days keep_results_in_days keep_important_results_in_days default_priority);
    for my $column (@columns) {
        $new_job_group->update({$column => $new_job_group->$column + 1000});
    }

    is($new_job_group->size_limit_gb,     OpenQA::Schema::JobGroupDefaults::SIZE_LIMIT_GB + 3000);
    is($new_job_group->keep_logs_in_days, OpenQA::Schema::JobGroupDefaults::KEEP_LOGS_IN_DAYS + 3000);
    is($new_job_group->keep_important_logs_in_days,
        OpenQA::Schema::JobGroupDefaults::KEEP_IMPORTANT_LOGS_IN_DAYS + 3000);
    is($new_job_group->keep_results_in_days, OpenQA::Schema::JobGroupDefaults::KEEP_RESULTS_IN_DAYS + 3000);
    is($new_job_group->keep_important_results_in_days,
        OpenQA::Schema::JobGroupDefaults::KEEP_IMPORTANT_RESULTS_IN_DAYS + 3000);
    is($new_job_group->default_priority, OpenQA::Schema::JobGroupDefaults::PRIORITY + 2000);
};

done_testing();
