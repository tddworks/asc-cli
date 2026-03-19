// Domain: Version state semantic booleans — mirrors Sources/Domain/Apps/Versions/AppStoreVersionState
export const VersionState = {
  isLive:     s => s === 'READY_FOR_SALE',
  isEditable: s => ['PREPARE_FOR_SUBMISSION','DEVELOPER_REJECTED','REJECTED','METADATA_REJECTED'].includes(s),
  isPending:  s => ['WAITING_FOR_REVIEW','IN_REVIEW','PENDING_DEVELOPER_RELEASE','PENDING_APPLE_RELEASE','PROCESSING_FOR_APP_STORE','WAITING_FOR_EXPORT_COMPLIANCE'].includes(s),
};
