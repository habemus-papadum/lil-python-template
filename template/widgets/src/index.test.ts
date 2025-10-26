import { describe, expect, it } from 'vitest';
import { renderWidget } from './widget';

describe('renderWidget', () => {
  it('renders title and body text', () => {
    const host = document.createElement('div');
    renderWidget(host, {
      title: 'Demo Title',
      body: 'Demo body',
    });

    expect(host.querySelector('h3')?.textContent).toBe('Demo Title');
    expect(host.querySelector('pre')?.textContent).toContain('Demo body');
  });
});
