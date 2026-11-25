// The Godot runtime is transported as gzip and streamed into WebAssembly.
const fetchAsset = window.fetch.bind(window);
window.fetch = async function (resource, options) {
    const url = new URL(resource instanceof Request ? resource.url : resource, document.baseURI);
    if (url.origin !== location.origin || !url.pathname.endsWith('/jogo.wasm')) {
        return fetchAsset(resource, options);
    }
    const packed = await fetchAsset(new URL('motor.bin', url), options);
    if (!packed.ok) throw new Error('Falha ao carregar o motor do jogo. Atualize a página para tentar novamente.');
    return new Response(packed.body.pipeThrough(new DecompressionStream('gzip')), {
        headers: {'Content-Type': 'application/wasm', 'Content-Length': '39514754'}
    });
};
