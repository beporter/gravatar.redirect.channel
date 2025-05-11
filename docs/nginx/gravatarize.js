async function gravatarizer(email) {
  const arrayBuffer = new TextEncoder('utf-8').encode(email);
  const hashAsArrayBuffer = await crypto.subtle.digest('SHA-256', arrayBuffer);
  const uint8ViewOfHash = new Uint8Array(hashAsArrayBuffer);
  return Array.from(uint8ViewOfHash).map((b) => b.toString(16).padStart(2, '0')).join('');
}

async function redirect(r) {
  const base_url = 'https://gravatar.com/avatar/';
  const query_string = '?' + new URLSearchParams({
      'd': 'identicon',
      's': '200'
  }).toString();

  const email = r.uri.split('/').at(-1).toLowerCase();
  const destination = base_url + await gravatarizer(email) + query_string;

  r.return(301, destination);
}

export default { redirect };
