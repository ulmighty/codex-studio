import { sendMessage } from '../shared/messageBus';

export function collectDOM(doc: Document): string[] {
  const result: string[] = [];
  const show = doc.defaultView?.NodeFilter.SHOW_ELEMENT ?? 1;
  const walker = doc.createTreeWalker(doc, show);
  let node = walker.nextNode() as HTMLElement | null;
  while (node) {
    result.push(node.tagName);
    node = walker.nextNode() as HTMLElement | null;
  }
  return result;
}

export function sendDomSnapshot(): void {
  const tags = collectDOM(document);
  sendMessage('dom-snapshot', tags);
}
