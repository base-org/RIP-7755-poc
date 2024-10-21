// A fetch wrapper that injects a configurable timeout parameter
export default async function safeFetch(
  url: string,
  params = {},
  timeout = 10000 // 10 seconds
): Promise<Response | null> {
  const controller = new AbortController();
  const { signal } = controller;
  const options = { ...params, signal };

  const id = setTimeout(() => controller.abort(), timeout);

  try {
    const res = await fetch(url, options);
    clearTimeout(id);
    return res;
  } catch (e) {
    console.error(e);
    return null;
  }
}
