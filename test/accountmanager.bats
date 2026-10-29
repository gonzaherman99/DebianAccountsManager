#!/usr/bin/env bats

@test "script exists and is executable" {
  [ -x ./AccountManagementSys.sh ]
}
