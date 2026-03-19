// Domain: CAEOAS affordance generators — mirrors AffordanceProviding protocol
import { VersionState } from './version-state.js';

export function appAffordances(app) {
  return {
    listVersions:  `asc versions list --app-id ${app.id}`,
    listAppInfos:  `asc app-infos list --app-id ${app.id}`,
    listReviews:   `asc reviews list --app-id ${app.id}`,
    listBuilds:    `asc builds list --app-id ${app.id}`,
    listBetaGroups:`asc testflight groups list --app-id ${app.id}`,
  };
}

export function versionAffordances(v) {
  const a = {
    listLocalizations: `asc version-localizations list --version-id ${v.id}`,
    listVersions:      `asc versions list --app-id ${v.appId}`,
    checkReadiness:    `asc versions check-readiness --version-id ${v.id}`,
    getReviewDetail:   `asc version-review-detail get --version-id ${v.id}`,
  };
  if (VersionState.isEditable(v.state)) a.submitForReview = `asc versions submit --version-id ${v.id}`;
  return a;
}

export function buildAffordances(b) {
  if (!b.isUsable) return {};
  return {
    addToTestFlight: `asc builds add-beta-group --build-id ${b.id} --beta-group-id <beta-group-id>`,
    updateBetaNotes: `asc builds update-beta-notes --build-id ${b.id} --locale en-US --notes <notes>`,
  };
}

export function betaGroupAffordances(g) {
  return {
    listTesters:   `asc testflight testers list --beta-group-id ${g.id}`,
    exportTesters: `asc testflight testers export --beta-group-id ${g.id}`,
    importTesters: `asc testflight testers import --beta-group-id ${g.id} --file testers.csv`,
  };
}

export function reviewAffordances(r) {
  return {
    getResponse: `asc review-responses get --review-id ${r.id}`,
    respond:     `asc review-responses create --review-id ${r.id} --response-body ""`,
    listReviews: `asc reviews list --app-id ${r.appId}`,
  };
}

export function iapAffordances(iap) {
  const a = {
    listLocalizations: `asc iap-localizations list --iap-id ${iap.id}`,
    listPricePoints:   `asc iap price-points list --iap-id ${iap.id}`,
    listOfferCodes:    `asc iap-offer-codes list --iap-id ${iap.id}`,
    getAvailability:   `asc iap-availability get --iap-id ${iap.id}`,
  };
  if (iap.state === 'READY_TO_SUBMIT') a.submit = `asc iap submit --iap-id ${iap.id}`;
  return a;
}

export function subGroupAffordances(sg) {
  return {
    listSubscriptions:  `asc subscriptions list --group-id ${sg.id}`,
    createSubscription: `asc subscriptions create --group-id ${sg.id} --name <name> --product-id <id> --period ONE_MONTH`,
  };
}

export function subscriptionAffordances(sub) {
  const a = {
    listLocalizations:      `asc subscription-localizations list --subscription-id ${sub.id}`,
    listIntroductoryOffers: `asc subscription-offers list --subscription-id ${sub.id}`,
    listOfferCodes:         `asc subscription-offer-codes list --subscription-id ${sub.id}`,
    getAvailability:        `asc subscription-availability get --subscription-id ${sub.id}`,
  };
  if (sub.state === 'READY_TO_SUBMIT') a.submit = `asc subscriptions submit --subscription-id ${sub.id}`;
  return a;
}

export function bundleIdAffordances(b) {
  return {
    delete:       `asc bundle-ids delete --bundle-id-id ${b.id}`,
    listProfiles: `asc profiles list --bundle-id-id ${b.id}`,
  };
}

export function certAffordances(c) {
  return { revoke: `asc certificates revoke --certificate-id ${c.id}` };
}

export function profileAffordances(p) {
  return {
    delete:       `asc profiles delete --profile-id ${p.id}`,
    listProfiles: `asc profiles list --bundle-id-id ${p.bundleIdId}`,
  };
}

export function teamMemberAffordances(u) {
  return {
    remove:      `asc users remove --user-id ${u.id}`,
    updateRoles: `asc users update --user-id ${u.id} ${u.roles.map(r => `--role ${r}`).join(' ')}`,
  };
}

export function invitationAffordances(inv) {
  return { cancel: `asc user-invitations cancel --invitation-id ${inv.id}` };
}

export function xcProductAffordances(p) {
  return {
    listWorkflows: `asc xcode-cloud workflows list --product-id ${p.id}`,
    listProducts:  `asc xcode-cloud products list --app-id ${p.appId}`,
  };
}

export function xcWorkflowAffordances(w) {
  const a = {
    listBuildRuns: `asc xcode-cloud builds list --workflow-id ${w.id}`,
    listWorkflows: `asc xcode-cloud workflows list --product-id ${w.productId}`,
  };
  if (w.isEnabled) a.startBuild = `asc xcode-cloud builds start --workflow-id ${w.id}`;
  return a;
}

export function xcBuildRunAffordances(br) {
  return {
    getBuildRun:   `asc xcode-cloud builds get --build-run-id ${br.id}`,
    listBuildRuns: `asc xcode-cloud builds list --workflow-id ${br.workflowId}`,
  };
}

export function authStatusAffordances() {
  return {
    check:  'asc auth check',
    list:   'asc auth list',
    login:  'asc auth login --key-id <id> --issuer-id <id> --private-key-path <path>',
    logout: 'asc auth logout',
  };
}
