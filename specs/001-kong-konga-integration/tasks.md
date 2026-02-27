# Tasks: Kong CE + Konga Integration

**Input**: Design documents from `/specs/001-kong-konga-integration/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, contracts/

**Tests**: Manual validation via health checks and API endpoints. No automated tests required for infrastructure deployment.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3, US4)
- Include exact file paths in descriptions

## Path Conventions

Infrastructure deployment project - configuration files and shell scripts at repository root.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and helper script creation

- [x] T001 Create scripts directory at scripts/
- [x] T002 Create config directory at config/
- [x] T003 Create backups directory at backups/
- [x] T004 [P] Create wait-for.sh helper script in scripts/wait-for.sh
- [x] T005 [P] Create health-check.sh helper script in scripts/health-check.sh

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core configuration that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T006 Update default.env with Kong 3.9 version variable KONG_VERSION
- [x] T007 [P] Update default.env with Konga configuration variables (KONGA_PORT, NODE_ENV, TOKEN_SECRET)
- [x] T008 [P] Update default.env with configurable port variables (KONG_PROXY_HTTP_PORT, KONG_PROXY_HTTPS_PORT, KONG_ADMIN_HTTP_PORT, KONG_ADMIN_HTTPS_PORT, KONG_MANAGER_PORT)
- [x] T009 Update default.env with PostgreSQL multiple database support variables
- [x] T010 Update docker-compose.yml with PostgreSQL 16 image and health check
- [x] T011 Update docker-compose.yml with database initialization for both kong and konga databases
- [x] T012 Update docker-compose.yml with Kong 3.9 service configuration using KONG_VERSION variable
- [x] T013 Update docker-compose.yml with Kong migrations service configuration
- [x] T014 Add Konga service definition to docker-compose.yml with PostgreSQL connection
- [x] T015 Add konga-database initialization to docker-compose.yml or use same PostgreSQL with multiple databases
- [x] T016 Configure kong-net Docker network for all services in docker-compose.yml
- [x] T017 Add Docker volumes for persistent storage (kong_data, konga_data) in docker-compose.yml
- [x] T018 Configure health checks for all services (PostgreSQL, Kong, Konga) in docker-compose.yml

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Deploy Complete API Gateway Stack (Priority: P1) 🎯 MVP

**Goal**: Deploy Kong CE 3.9+ with Konga and PostgreSQL with single setup script

**Independent Test**: Run `./setup.sh` and verify all services (Kong, Konga, PostgreSQL) are healthy via health checks and accessible endpoints

### Implementation for User Story 1

- [x] T019 [US1] Update setup.sh to start kong-database service
- [x] T020 [US1] Update setup.sh to wait for database health check using scripts/wait-for.sh
- [x] T021 [US1] Update setup.sh to run Kong migrations with kong migrations bootstrap
- [x] T022 [US1] Update setup.sh to start Kong service and wait for health check
- [x] T023 [US1] Update setup.sh to start Konga service and wait for readiness
- [x] T024 [US1] Add service endpoint summary output to setup.sh (Admin API, Proxy, Konga URLs)
- [x] T025 [US1] Add error handling and rollback instructions to setup.sh
- [x] T026 [US1] Create sample declarative config file at config/kong.yaml (optional for DB-less fallback)
- [x] T027 [US1] Update README.md with updated architecture diagram showing Kong + Konga + PostgreSQL

**Checkpoint**: At this point, User Story 1 should be fully functional - complete stack deployable with `./setup.sh`

---

## Phase 4: User Story 2 - Manage APIs via Web GUI (Priority: P2)

**Goal**: Enable Kong configuration management through Konga web interface

**Independent Test**: Access Konga at port 1337, create Kong connection, create service and route via GUI, verify route works through Kong proxy

### Implementation for User Story 2

- [x] T028 [US2] Update README.md with Konga first-time setup instructions (create admin user, configure Kong connection)
- [x] T029 [US2] Add Konga connection URL documentation (http://kong:8001 internal vs http://localhost:8001 external) to README.md
- [x] T030 [US2] Add example workflow for creating service and route through Konga to README.md
- [x] T031 [US2] Update quickstart.md with Konga GUI screenshots placeholder and detailed steps

**Checkpoint**: At this point, Users can manage Kong configuration entirely through the Konga web GUI

---

## Phase 5: User Story 3 - Upgrade Kong Version (Priority: P3)

**Goal**: Enable safe Kong version upgrades with migration support

**Independent Test**: Change KONG_VERSION in .env, run upgrade.sh, verify all existing routes remain functional

### Implementation for User Story 3

- [x] T032 [US3] Create upgrade.sh script with backup step before upgrade
- [x] T033 [US3] Add `kong migrations up` command execution to upgrade.sh
- [x] T034 [US3] Add `kong migrations finish` command execution to upgrade.sh
- [x] T035 [US3] Add version verification and health check after upgrade in upgrade.sh
- [x] T036 [US3] Add rollback instructions if upgrade fails in upgrade.sh
- [x] T037 [US3] Update README.md with detailed upgrade procedure section

**Checkpoint**: At this point, Kong version upgrades can be performed safely with documented procedure

---

## Phase 6: User Story 4 - Backup and Restore Configuration (Priority: P4)

**Goal**: Enable database backup and restore for disaster recovery

**Independent Test**: Run backup.sh, make config changes, run restore.sh, verify original state restored

### Implementation for User Story 4

- [x] T038 [US4] Create backup.sh script with timestamp-based backup filenames
- [x] T039 [US4] Add pg_dump for kong database to backup.sh
- [x] T040 [US4] Add pg_dump for konga database to backup.sh
- [x] T041 [US4] Add backup directory creation and file permissions to backup.sh
- [x] T042 [US4] Create restore.sh script with database selection (kong/konga/both)
- [x] T043 [US4] Add psql restore command with error handling to restore.sh
- [x] T044 [US4] Add warning prompt before restore to restore.sh (destructive operation)
- [x] T045 [US4] Update README.md with backup and restore documentation

**Checkpoint**: All user stories should now be independently functional

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [x] T046 [P] Add .gitignore entries for .env, backups/, and sensitive files
- [x] T047 [P] Add Docker Compose override file example (docker-compose.override.yml.example) for custom configurations
- [x] T048 [P] Update README.md with complete table of environment variables
- [x] T049 [P] Add troubleshooting section to README.md with common issues
- [x] T050 [P] Add security considerations section to README.md
- [x] T051 Run quickstart.md validation to ensure all commands work as documented
- [x] T052 Remove outdated Kong Manager references (Enterprise feature, limited in CE)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-6)**: All depend on Foundational phase completion
  - User stories can then proceed in parallel (if staffed)
  - Or sequentially in priority order (P1 → P2 → P3 → P4)
- **Polish (Phase 7)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P2)**: Can start after Foundational (Phase 2) - Documentation-only, no code dependencies
- **User Story 3 (P3)**: Can start after Foundational (Phase 2) - Creates new script, independent
- **User Story 4 (P4)**: Can start after Foundational (Phase 2) - Creates new scripts, independent

### Within Each User Story

- Configuration files before scripts that use them
- Core implementation before documentation
- Story complete before moving to next priority

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel
- All Foundational tasks marked [P] can run in parallel (within Phase 2)
- Once Foundational phase completes, all user stories can start in parallel
- All Polish tasks marked [P] can run in parallel

---

## Parallel Example: Phase 2 Foundational

```bash
# These environment variable updates can run in parallel:
Task: "Update default.env with Konga configuration variables"
Task: "Update default.env with configurable port variables"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: Run `./setup.sh` and verify all services healthy
5. Deploy/demo if ready

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 → Test independently → Deploy/Demo (MVP!)
3. Add User Story 2 → Test independently → Deploy/Demo
4. Add User Story 3 → Test independently → Deploy/Demo
5. Add User Story 4 → Test independently → Deploy/Demo
6. Each story adds value without breaking previous stories

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: User Story 1 (core deployment)
   - Developer B: User Story 2 (Konga documentation)
   - Developer C: User Story 3 (upgrade script)
   - Developer D: User Story 4 (backup/restore scripts)
3. Stories complete and integrate independently

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Avoid: vague tasks, same file conflicts, cross-story dependencies that break independence
