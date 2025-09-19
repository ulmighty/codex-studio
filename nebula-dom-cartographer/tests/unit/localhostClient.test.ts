import { inferLocal, hasAllowNetworkAnnotation } from '../../extension/ai/adapter/localhostClient';

describe('network guard', () => {
  const json = jest.fn().mockResolvedValue({ ok: true });
  const fetchMock = jest.fn().mockResolvedValue({ json });

  beforeEach(() => {
    json.mockClear();
    fetchMock.mockClear();
    (globalThis as typeof globalThis & { fetch: typeof fetch }).fetch =
      fetchMock as unknown as typeof fetch;
  });

  it('rejects payloads without @allow-network', async () => {
    await expect(inferLocal({ prompt: 'hello' })).rejects.toThrow('Network egress blocked');
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it('permits payloads with annotation array', async () => {
    const result = await inferLocal({ prompt: 'hi', annotations: ['@allow-network'] });
    expect(fetchMock).toHaveBeenCalledTimes(1);
    expect(result).toEqual({ ok: true });
  });

  it('detects annotation in nested metadata', () => {
    expect(
      hasAllowNetworkAnnotation({ metadata: { annotations: ['@allow-network'] } }),
    ).toBe(true);
  });
});
