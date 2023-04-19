window.soundwaveActions = () => {
    console.log('calling soundwave azctions')
    if (document.querySelector('.loader').classList.contains('active')) {
        document.querySelectorAll('.line').forEach(el => {el.classList.remove('stroke'); el.classList.add('small')})
        setTimeout(()=>{
            window.hideLoader = false;
            var el = document.querySelector('.loader')
            el.classList.remove('active')
            el.classList.add('inactive')
            var transitionEnd = (e) => {
                el.style.display = "none";
                if (!window.hideLoader) window.toggleTranscribeLoader(true);
                el.removeEventListener("transitionend", transitionEnd)
            }
            el.addEventListener('transitionend', transitionEnd)
        },500)
    } else {
        document.querySelectorAll('.line').forEach(el => {el.classList.remove('small'); el.classList.add('stroke')})
        var el = document.querySelector('.loader')
        el.classList.remove('inactive')
        el.classList.add('active')
    }
}

window.toggleTranscribeLoader = (state) => {
    var el = document.querySelector('.progress')
    if (!state) {
        el.style.display = "none"
        document.querySelector('.loader').style = ""
    } else {
        el.style = ""
    }
}
