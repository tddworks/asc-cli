# Users & Roles

Manage App Store Connect team members and pending user invitations. Integrates with your organisation's directory for automated access control — e.g. revoke access when a user leaves.

---

## CLI Usage

### `asc users`

#### list

```
asc users list [--role <ROLE>]
```

| Flag | Required | Description |
|------|----------|-------------|
| `--role` | No | Filter by role (uppercase, e.g. `ADMIN`, `DEVELOPER`) |

**Example:**
```bash
asc users list --pretty
asc users list --role DEVELOPER --output table
```

**JSON output:**
```json
{
  "data": [
    {
      "affordances": {
        "remove": "asc users remove --user-id u-1",
        "updateRoles": "asc users update --user-id u-1 --role DEVELOPER --role APP_MANAGER"
      },
      "firstName": "Jane",
      "id": "u-1",
      "isAllAppsVisible": false,
      "isProvisioningAllowed": true,
      "lastName": "Doe",
      "roles": ["DEVELOPER", "APP_MANAGER"],
      "username": "jdoe@example.com"
    }
  ]
}
```

#### update

Replace a team member's roles.

```
asc users update --user-id <id> --role <ROLE> [--role <ROLE> ...]
```

| Flag | Required | Description |
|------|----------|-------------|
| `--user-id` | Yes | User resource ID |
| `--role` | Yes (repeatable) | Role to assign (uppercase). Multiple `--role` flags allowed |

**Example:**
```bash
asc users update --user-id u-abc --role APP_MANAGER --role DEVELOPER
```

#### remove

Revoke a team member's access immediately.

```
asc users remove --user-id <id>
```

| Flag | Required | Description |
|------|----------|-------------|
| `--user-id` | Yes | User resource ID |

**Example:**
```bash
# Revoke access for a departing employee
asc users remove --user-id u-abc
```

---

### `asc user-invitations`

#### list

```
asc user-invitations list [--role <ROLE>]
```

| Flag | Required | Description |
|------|----------|-------------|
| `--role` | No | Filter by role (e.g. `ADMIN`, `DEVELOPER`) |

**JSON output:**
```json
{
  "data": [
    {
      "affordances": {
        "cancel": "asc user-invitations cancel --invitation-id inv-1"
      },
      "email": "new@example.com",
      "firstName": "New",
      "id": "inv-1",
      "isAllAppsVisible": false,
      "isProvisioningAllowed": false,
      "lastName": "User",
      "roles": ["DEVELOPER"]
    }
  ]
}
```

#### invite

Send a team invitation.

```
asc user-invitations invite --email <email> --first-name <name> --last-name <name> --role <ROLE> [--role <ROLE> ...] [--all-apps-visible]
```

| Flag | Required | Description |
|------|----------|-------------|
| `--email` | Yes | Email address of the invitee |
| `--first-name` | Yes | First name |
| `--last-name` | Yes | Last name |
| `--role` | Yes (repeatable) | Role to assign |
| `--all-apps-visible` | No | Grant access to all apps (default: false) |

**Example:**
```bash
asc user-invitations invite \
  --email new-hire@example.com \
  --first-name Alex \
  --last-name Smith \
  --role DEVELOPER \
  --role APP_MANAGER
```

#### cancel

Cancel a pending invitation.

```
asc user-invitations cancel --invitation-id <id>
```

| Flag | Required | Description |
|------|----------|-------------|
| `--invitation-id` | Yes | User invitation resource ID |

---

## Available Roles

| Role | Raw value |
|------|-----------|
| Admin | `ADMIN` |
| Finance | `FINANCE` |
| Account Holder | `ACCOUNT_HOLDER` |
| Sales | `SALES` |
| Marketing | `MARKETING` |
| App Manager | `APP_MANAGER` |
| Developer | `DEVELOPER` |
| Access to Reports | `ACCESS_TO_REPORTS` |
| Customer Support | `CUSTOMER_SUPPORT` |
| Create Apps | `CREATE_APPS` |
| Cloud Managed Developer ID | `CLOUD_MANAGED_DEVELOPER_ID` |
| Cloud Managed App Distribution | `CLOUD_MANAGED_APP_DISTRIBUTION` |
| Generate Individual Keys | `GENERATE_INDIVIDUAL_KEYS` |

---

## Typical Workflow

### Directory integration — revoke access on offboarding

```bash
#!/usr/bin/env bash
# Revoke App Store Connect access for a departing employee by email

DEPARTED_EMAIL="former-employee@example.com"

USER_ID=$(asc users list | jq -r --arg email "$DEPARTED_EMAIL" \
  '.data[] | select(.username == $email) | .id')

if [ -n "$USER_ID" ]; then
  asc users remove --user-id "$USER_ID"
  echo "Access revoked for $DEPARTED_EMAIL"
else
  # Check for a pending invitation
  INV_ID=$(asc user-invitations list | jq -r --arg email "$DEPARTED_EMAIL" \
    '.data[] | select(.email == $email) | .id')
  if [ -n "$INV_ID" ]; then
    asc user-invitations cancel --invitation-id "$INV_ID"
    echo "Pending invitation cancelled for $DEPARTED_EMAIL"
  else
    echo "No active user or invitation found for $DEPARTED_EMAIL"
  fi
fi
```

### Onboard a new developer

```bash
asc user-invitations invite \
  --email new-dev@example.com \
  --first-name Alex \
  --last-name Smith \
  --role DEVELOPER
```

### Promote a developer to App Manager

```bash
USER_ID=$(asc users list --role DEVELOPER | jq -r '.data[] | select(.username == "dev@example.com") | .id')
asc users update --user-id "$USER_ID" --role APP_MANAGER --role DEVELOPER
```

---

## Architecture

```
UsersCommand / UserInvitationsCommand   (ASCCommand)
        │
        ▼
UserRepository  (Domain — @Mockable protocol)
        │
        ▼
SDKUserRepository  (Infrastructure — appstoreconnect-swift-sdk)
        │
        ▼
GET/PATCH/DELETE /v1/users
GET/POST/DELETE  /v1/userInvitations
```

---

## Domain Models

### `TeamMember`

| Field | Type | Description |
|-------|------|-------------|
| `id` | `String` | Resource ID |
| `username` | `String` | Email / Apple ID username |
| `firstName` | `String` | First name |
| `lastName` | `String` | Last name |
| `roles` | `[UserRole]` | Assigned roles |
| `isAllAppsVisible` | `Bool` | Can access all apps |
| `isProvisioningAllowed` | `Bool` | Can manage provisioning |

**Affordances:**
- `remove` — `asc users remove --user-id <id>`
- `updateRoles` — `asc users update --user-id <id> --role <current roles...>`

### `UserInvitationRecord`

| Field | Type | Description |
|-------|------|-------------|
| `id` | `String` | Resource ID |
| `email` | `String` | Invitee email |
| `firstName` | `String` | First name |
| `lastName` | `String` | Last name |
| `roles` | `[UserRole]` | Roles to assign on acceptance |
| `expirationDate` | `Date?` | When the invitation expires (omitted from JSON if nil) |
| `isAllAppsVisible` | `Bool` | All-apps access flag |
| `isProvisioningAllowed` | `Bool` | Provisioning flag |

**Affordances:**
- `cancel` — `asc user-invitations cancel --invitation-id <id>`

### `UserRole`

`String`-backed enum with 13 cases. `cliArgument` initialiser accepts uppercase or lowercase values (e.g. `"admin"` → `.admin`).

---

## File Map

### Sources
```
Sources/Domain/Users/
  UserRole.swift                     — UserRole enum (13 cases, cliArgument init, displayName)
  TeamMember.swift                   — TeamMember model + AffordanceProviding
  UserInvitationRecord.swift         — UserInvitationRecord model + AffordanceProviding
  UserRepository.swift               — @Mockable UserRepository protocol

Sources/Infrastructure/Users/
  SDKUserRepository.swift            — SDK adapter (listUsers, updateUser, removeUser,
                                       listUserInvitations, inviteUser, cancelUserInvitation)

Sources/ASCCommand/Commands/Users/
  UsersCommand.swift                 — asc users (list/update/remove)
  UsersList.swift                    — asc users list
  UsersUpdate.swift                  — asc users update
  UsersRemove.swift                  — asc users remove
  UserInvitationsCommand.swift       — asc user-invitations (list/invite/cancel)
  UserInvitationsList.swift          — asc user-invitations list
  UserInvitationsInvite.swift        — asc user-invitations invite
  UserInvitationsCancel.swift        — asc user-invitations cancel
```

### Wiring
| File | Change |
|------|--------|
| `Sources/ASCCommand/ASC.swift` | Registered `UsersCommand`, `UserInvitationsCommand` |
| `Sources/ASCCommand/ClientProvider.swift` | Added `makeUserRepository()` |
| `Sources/Infrastructure/Client/ClientFactory.swift` | Added `makeUserRepository(authProvider:)` |

### Tests
```
Tests/ASCCommandTests/Commands/Users/
  UsersListTests.swift
  UsersUpdateTests.swift
  UsersRemoveTests.swift
  UserInvitationsListTests.swift
  UserInvitationsInviteTests.swift
  UserInvitationsCancelTests.swift

Tests/InfrastructureTests/Users/
  SDKUserRepositoryTests.swift
```

---

## API Reference

| Operation | Endpoint | SDK call |
|-----------|----------|----------|
| List users | `GET /v1/users` | `APIEndpoint.v1.users.get(parameters:)` |
| Update user | `PATCH /v1/users/{id}` | `APIEndpoint.v1.users.id(id).patch(_:)` |
| Remove user | `DELETE /v1/users/{id}` | `APIEndpoint.v1.users.id(id).delete` |
| List invitations | `GET /v1/userInvitations` | `APIEndpoint.v1.userInvitations.get(parameters:)` |
| Send invitation | `POST /v1/userInvitations` | `APIEndpoint.v1.userInvitations.post(_:)` |
| Cancel invitation | `DELETE /v1/userInvitations/{id}` | `APIEndpoint.v1.userInvitations.id(id).delete` |

---

## Testing

```bash
swift test --filter 'Users'
swift test --filter 'UserInvitation'
```

Representative test (command layer):

```swift
@Test func `listed users include roles and affordances`() async throws {
    let mockRepo = MockUserRepository()
    given(mockRepo).listUsers(role: .any).willReturn([
        TeamMember(id: "u-1", username: "jdoe@example.com",
                   firstName: "Jane", lastName: "Doe",
                   roles: [.developer, .appManager],
                   isAllAppsVisible: false, isProvisioningAllowed: true),
    ])
    let cmd = try UsersList.parse(["--pretty"])
    let output = try await cmd.execute(repo: mockRepo)
    #expect(output.contains("asc users remove --user-id u-1"))
}
```

---

## Extending

Natural next steps:

- **Filter by app** — pass `filterVisibleApps: [appId]` to `GetParameters`; add `--app-id` flag to `UsersList`
- **Manage visible apps** — `PATCH /v1/users/{id}/relationships/visibleApps` to restrict per-app access
- **Invitation visible apps** — add `--app-id` to `UserInvitationsInvite` and pass `relationships.visibleApps`
