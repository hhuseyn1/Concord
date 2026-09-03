import { uploadFile, uploadFileWithProgress } from './httpClient';

export async function uploadAvatar(file) {
  return uploadFile('Files/Avatar', file);
}

export async function uploadServerIcon(file) {
  return uploadFile('Files/ServerIcon', file);
}

export async function uploadAttachment(file) {
  return uploadFile('Files/Attachment', file);
}

export function uploadAttachmentWithProgress(file, onProgress) {
  return uploadFileWithProgress('Files/Attachment', file, onProgress);
}
