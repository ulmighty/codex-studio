import { JSDOM } from 'jsdom';
import { collectDOM } from '../../extension/content/domCollector';

test('collectDOM captures tags', () => {
  const dom = new JSDOM('<html><body><div></div><span></span></body></html>');
  const tags = collectDOM(dom.window.document);
  expect(tags).toEqual(['HTML', 'HEAD', 'BODY', 'DIV', 'SPAN']);
});
