#!/usr/bin/env escript
%% -*- erlang -*-

% Licensed under the Apache License, Version 2.0 (the "License"); you may not
% use this file except in compliance with the License. You may obtain a copy of
% the License at
%
%   http://www.apache.org/licenses/LICENSE-2.0
%
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
% WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
% License for the specific language governing permissions and limitations under
% the License.

main(_) ->
    etap:plan(12),
    case (catch test()) of
        ok ->
            etap:end_tests();
        Other ->
            etap:diag(io_lib:format("Test died abnormally: ~p", [Other])),
            etap:bail(Other)
    end,
    timer:sleep(300),
    ok.

sig() -> <<"02797edfda2d778b73dd67259d84f93f">>.

test() ->
    test_util:start_couch(),

    {ok, Db} = couch_mrview_test_util:init_db(<<"foo">>, map),
    couch_mrview:query_view(Db, <<"_design/bar">>, <<"baz">>),

    {ok, Info} = couch_mrview:get_info(Db, <<"_design/bar">>),

    etap:is(getval(signature, Info), sig(), "Signature is ok."),
    etap:is(getval(language, Info), <<"javascript">>, "Language is ok."),
    etap:is_greater(getval(disk_size, Info), 0, "Disk size is ok."),
    etap:is_greater(getval(data_size, Info), 0, "Data size is ok."),
    etap:is(getval(update_seq, Info), 11, "Update seq is ok."),
    etap:is(getval(purge_seq, Info), 0, "Purge seq is ok."),
    etap:is(getval(updater_running, Info), false, "No updater running."),
    etap:is(getval(compact_running, Info), false, "No compaction running."),
    etap:is(getval(waiting_clients, Info), 0, "No waiting clients."),


    {ok, ViewInfo} = couch_mrview:get_view_info(Db, <<"_design/bar">>,
                                           <<"baz">>),
    etap:is(getval(update_seq, ViewInfo), 11, "View Update seq is ok."),
    etap:is(getval(purge_seq, ViewInfo), 0, "View Update seq is ok."),
    etap:is(getval(total_rows, ViewInfo), 10, "View total rows is ok."),


    test_util:stop_couch(),
    ok.

getval(Key, PL) ->
    {value, {Key, Val}} = lists:keysearch(Key, 1, PL),
    Val.
