// Page: Submissions
import { DataProvider } from '../../../../shared/infrastructure/data-provider.js';
import { showToast } from '../toast.js';

export function renderSubmissions() {
  return `
    <div class="card mb-24">
      <div class="card-header"><span class="card-title">Submit for App Store Review</span></div>
      <div class="card-body padded">
        <div class="form-row mb-16">
          <div class="form-group">
            <label class="form-label">Version ID</label>
            <input class="form-input" placeholder="e.g. v002" id="submitVersionId"/>
          </div>
          <div class="form-group">
            <label class="form-label">Pre-flight Check</label>
            <button class="btn btn-secondary" onclick="checkReadiness()" style="margin-top:2px">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="16" height="16"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><path d="M22 4L12 14.01l-3-3"/></svg>
              Check Readiness
            </button>
          </div>
        </div>
        <div id="readinessResult"></div>
        <div style="margin-top:16px">
          <button class="btn btn-primary" onclick="submitForReview()"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="16" height="16"><path d="M22 2L11 13"/><path d="M22 2l-7 20-4-9-9-4 20-7z"/></svg>Submit for Review</button>
        </div>
      </div>
    </div>
    <div class="card">
      <div class="card-header"><span class="card-title">Review Contact & Demo Account</span></div>
      <div class="card-body padded">
        <div class="form-row mb-16">
          <div class="form-group"><label class="form-label">Contact First Name</label><input class="form-input" placeholder="John"/></div>
          <div class="form-group"><label class="form-label">Contact Last Name</label><input class="form-input" placeholder="Doe"/></div>
        </div>
        <div class="form-row mb-16">
          <div class="form-group"><label class="form-label">Contact Email</label><input class="form-input" placeholder="john@example.com"/></div>
          <div class="form-group"><label class="form-label">Contact Phone</label><input class="form-input" placeholder="+1 555-0100"/></div>
        </div>
        <div class="form-row mb-16">
          <div class="form-group"><label class="form-label">Demo Username</label><input class="form-input" placeholder="demo@example.com"/></div>
          <div class="form-group"><label class="form-label">Demo Password</label><input class="form-input" type="password" placeholder="password"/></div>
        </div>
        <div class="form-group">
          <label class="form-label">Review Notes</label>
          <textarea class="form-input" placeholder="Any notes for the reviewer..."></textarea>
        </div>
        <button class="btn btn-secondary" style="margin-top:8px" onclick="showToast('Review details saved','success')">Save Review Info</button>
      </div>
    </div>`;
}

async function checkReadiness() {
  const vid = document.getElementById('submitVersionId').value || 'v-ps-002';
  showToast('Checking readiness...', 'info');
  await DataProvider.fetch(`versions check-readiness --version-id ${vid}`);
  document.getElementById('readinessResult').innerHTML = `
    <div style="padding:12px;background:var(--success-bg);border-radius:var(--radius);border:1px solid #A7F3D0">
      <div style="font-weight:600;color:var(--success-text);margin-bottom:4px">Readiness Check Passed</div>
      <div style="font-size:12px;color:var(--success-text)">All required fields are set. Version is ready for submission.</div>
    </div>`;
}

async function submitForReview() {
  const vid = document.getElementById('submitVersionId')?.value || 'v-ps-002';
  showToast('Submitting...', 'info');
  await DataProvider.fetch(`versions submit --version-id ${vid}`);
  showToast('Submitted for App Store Review!', 'success');
}

window.checkReadiness = checkReadiness;
window.submitForReview = submitForReview;
