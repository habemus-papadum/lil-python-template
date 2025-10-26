import { renderWidget } from './widget';
import type { WidgetPayload } from './types';
import { VERSION } from './version';

export interface InitOptions {
  target: HTMLElement;
  payload: WidgetPayload;
}

export function initWidget(options: InitOptions) {
  renderWidget(options.target, options.payload);
}

export { renderWidget, VERSION };
export type { WidgetPayload };
