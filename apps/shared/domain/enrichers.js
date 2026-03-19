// Domain: Enrich raw data with semantic booleans + affordances
import { VersionState } from './version-state.js';
import {
  appAffordances, versionAffordances, buildAffordances,
  betaGroupAffordances, reviewAffordances, iapAffordances,
  subGroupAffordances, subscriptionAffordances, bundleIdAffordances,
  certAffordances, profileAffordances, teamMemberAffordances,
  invitationAffordances, xcProductAffordances, xcWorkflowAffordances,
  xcBuildRunAffordances,
} from './affordances.js';

export function enrichApp(raw) {
  return { ...raw, displayName: raw.name || raw.bundleId, affordances: appAffordances(raw) };
}

export function enrichVersion(raw) {
  return {
    ...raw,
    isLive: VersionState.isLive(raw.state),
    isEditable: VersionState.isEditable(raw.state),
    isPending: VersionState.isPending(raw.state),
    affordances: versionAffordances(raw),
  };
}

export function enrichBuild(raw) {
  const isUsable = !raw.expired && raw.processingState === 'VALID';
  return { ...raw, isUsable, affordances: buildAffordances({ ...raw, isUsable }) };
}

export function enrichBetaGroup(raw)  { return { ...raw, affordances: betaGroupAffordances(raw) }; }
export function enrichReview(raw)     { return { ...raw, affordances: reviewAffordances(raw) }; }

export function enrichIAP(raw) {
  const isLive = raw.state === 'APPROVED';
  const isEditable = ['MISSING_METADATA','REJECTED','DEVELOPER_ACTION_NEEDED'].includes(raw.state);
  return { ...raw, isLive, isEditable, affordances: iapAffordances(raw) };
}

export function enrichSubGroup(raw)   { return { ...raw, affordances: subGroupAffordances(raw) }; }

export function enrichSubscription(raw) {
  const isLive = raw.state === 'APPROVED';
  const isEditable = ['MISSING_METADATA','REJECTED','DEVELOPER_ACTION_NEEDED'].includes(raw.state);
  return { ...raw, isLive, isEditable, affordances: subscriptionAffordances(raw) };
}

export function enrichBundleId(raw)   { return { ...raw, affordances: bundleIdAffordances(raw) }; }

export function enrichCert(raw) {
  const isExpired = raw.expirationDate ? new Date(raw.expirationDate) < new Date() : false;
  return { ...raw, isExpired, affordances: certAffordances(raw) };
}

export function enrichProfile(raw) {
  const isActive = raw.profileState === 'ACTIVE';
  return { ...raw, isActive, affordances: profileAffordances(raw) };
}

export function enrichTeamMember(raw) { return { ...raw, affordances: teamMemberAffordances(raw) }; }
export function enrichInvitation(raw) { return { ...raw, affordances: invitationAffordances(raw) }; }
export function enrichXCProduct(raw)  { return { ...raw, affordances: xcProductAffordances(raw) }; }
export function enrichXCWorkflow(raw) { return { ...raw, affordances: xcWorkflowAffordances(raw) }; }

export function enrichXCBuildRun(raw) {
  const ep = raw.executionProgress;
  return {
    ...raw,
    isPending: ep === 'PENDING', isRunning: ep === 'RUNNING', isComplete: ep === 'COMPLETE',
    isSucceeded: raw.completionStatus === 'SUCCEEDED',
    hasFailed: ['FAILED','ERRORED'].includes(raw.completionStatus),
    affordances: xcBuildRunAffordances(raw),
  };
}
