window.addEventListener('message', function(event) {
    let data = event.data;
    let icon = document.getElementById('zone-icon');
    let image = document.getElementById('zone-image');
    let debug = data.debug || false;

    if (debug) console.log('NUI got:', JSON.stringify(data));
    if (data.action == 'show') {
        image.src = data.image;
        icon.classList.remove('hidden');
        if (debug) console.log('Showing:', data.image);
    } else if (data.action == 'hide') {
        icon.classList.add('hidden');
        if (debug) console.log('Hiding image');
    } else if (data.action == 'setPosition') {
        icon.style.right = data.x;
        icon.style.top = data.y;
        if (debug) console.log('Moved UI to x=' + data.x + ', y=' + data.y);
    }
});