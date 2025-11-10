(function (global) {
  function Toastify(options) {
    var opts = options || {};
    var el = document.createElement('div');
    el.className = 'toastify';
    el.textContent = opts.text || '';
    el.style.position = 'fixed';
    el.style.padding = '12px 16px';
    el.style.borderRadius = '4px';
    el.style.boxShadow = '0 2px 8px rgba(0,0,0,0.3)';
    el.style.background = opts.backgroundColor || 'rgba(0,0,0,0.85)';
    el.style.color = opts.textColor || '#fff';
    var duration = typeof opts.duration === 'number' ? opts.duration : 3000;

    var gravity = (opts.gravity === 'bottom') ? 'bottom' : 'top';
    var position = (opts.position === 'left' || opts.position === 'center') ? opts.position : 'right';
    el.style[gravity] = '16px';
    if (position === 'left') {
      el.style.left = '16px';
    } else if (position === 'center') {
      el.style.left = '50%';
      el.style.transform = 'translateX(-50%)';
    } else {
      el.style.right = '16px';
    }

    return {
      showToast: function () {
        document.body.appendChild(el);
        setTimeout(function () {
          if (el && el.parentNode) {
            el.parentNode.removeChild(el);
          }
        }, duration);
      }
    };
  }

  global.Toastify = Toastify;
})(window);
