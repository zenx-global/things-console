import Foundation

/// 手机速录页面：单文件 HTML + 原生 JS，无构建步骤。
/// 照片走 file input（HTTP 非安全上下文下 getUserMedia 在 iOS 被禁），前端压缩到 ≤1280px。
enum CompanionPage {

    static let html = ##"""
<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<meta name="theme-color" content="#f6f6f4" media="(prefers-color-scheme: light)">
<meta name="theme-color" content="#17171a" media="(prefers-color-scheme: dark)">
<title>速录 · 物品管理台</title>
<style>
:root {
  color-scheme: light dark;
  --bg: #f6f6f4; --card: #ffffff; --text: #1d1d1f;
  --muted: #8a8a8e; --line: #e6e6e2; --accent: #0a84ff;
}
@media (prefers-color-scheme: dark) {
  :root {
    --bg: #17171a; --card: #202024; --text: #f2f2f5;
    --muted: #98989d; --line: #2d2d31;
  }
}
* { box-sizing: border-box; margin: 0; padding: 0; -webkit-tap-highlight-color: transparent; }
html { -webkit-text-size-adjust: 100%; }
body {
  font-family: -apple-system, BlinkMacSystemFont, "PingFang SC", sans-serif;
  background: var(--bg); color: var(--text); font-size: 16px;
  padding-bottom: 118px;
}
.wrap { max-width: 560px; margin: 0 auto; padding: 14px 16px 0; }
h1 { font-size: 19px; font-weight: 700; margin: 6px 2px 14px; letter-spacing: .3px; }
.card {
  background: var(--card); border: 1px solid var(--line);
  border-radius: 14px; padding: 14px; margin-bottom: 14px;
}
label { display: block; font-size: 13px; color: var(--muted); margin: 10px 2px 6px; }
label:first-child { margin-top: 0; }
input, select {
  width: 100%; font-size: 17px; padding: 11px 12px;
  border: 1px solid var(--line); border-radius: 10px;
  background: var(--bg); color: var(--text);
  -webkit-appearance: none; appearance: none;
}
input:focus, select:focus { outline: 2px solid var(--accent); outline-offset: -1px; }
.row { display: flex; gap: 10px; }
.row .grow { flex: 1; }
.row .narrow { max-width: 110px; }
.photos { display: flex; flex-wrap: wrap; gap: 8px; margin-top: 8px; }
.photos img {
  width: 64px; height: 64px; object-fit: cover;
  border-radius: 8px; border: 1px solid var(--line);
}
.add-photo {
  width: 64px; height: 64px; border: 1.5px dashed var(--muted);
  border-radius: 8px; display: flex; align-items: center; justify-content: center;
  font-size: 26px; color: var(--muted);
}
.save-bar {
  position: fixed; left: 0; right: 0; bottom: 0;
  padding: 12px 16px calc(12px + env(safe-area-inset-bottom));
  background: linear-gradient(transparent, var(--bg) 32%);
}
.save {
  display: block; width: 100%; max-width: 528px; margin: 0 auto;
  font-size: 17px; font-weight: 600; padding: 14px;
  border: 0; border-radius: 12px; background: var(--accent); color: #fff;
}
.save:disabled { opacity: .5; }
.toast {
  position: fixed; top: 14px; left: 50%; transform: translateX(-50%);
  background: var(--text); color: var(--bg); font-size: 14px;
  padding: 9px 18px; border-radius: 99px; opacity: 0;
  transition: opacity .2s; pointer-events: none; z-index: 9;
}
.toast.show { opacity: .92; }
.list { list-style: none; }
.list li {
  display: flex; align-items: center; gap: 12px;
  padding: 9px 0; border-bottom: 1px solid var(--line);
}
.list li:last-child { border-bottom: 0; }
.thumb {
  width: 44px; height: 44px; border-radius: 8px; overflow: hidden;
  background: var(--line); flex: none;
  display: flex; align-items: center; justify-content: center; font-size: 20px;
}
.thumb img { width: 100%; height: 100%; object-fit: cover; }
.meta { flex: 1; min-width: 0; }
.name { font-weight: 600; font-size: 15px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.sub { font-size: 12.5px; color: var(--muted); margin-top: 2px; font-variant-numeric: tabular-nums; }
.empty { border: 0; color: var(--muted); font-size: 13.5px; justify-content: center; padding: 14px 0; }
.hint { font-size: 12.5px; color: var(--muted); margin-top: 2px; line-height: 1.7; }
</style>
</head>
<body>
<div class="wrap">
  <h1>速录</h1>
  <div class="card">
    <label for="name">名称</label>
    <input id="name" placeholder="物品名称" autocomplete="off" autocapitalize="off">
    <label for="category">分类</label>
    <select id="category"></select>
    <div class="row">
      <div class="grow">
        <label for="location">位置</label>
        <input id="location" list="loc-list" placeholder="如：书房抽屉" autocomplete="off">
        <datalist id="loc-list"></datalist>
      </div>
      <div class="narrow">
        <label for="quantity">数量</label>
        <input id="quantity" type="number" inputmode="numeric" min="1" value="1">
      </div>
    </div>
    <label>照片（可多选）</label>
    <input id="photo-input" type="file" accept="image/*" multiple hidden>
    <div class="photos" id="photos"></div>
  </div>
  <div class="card">
    <div style="font-size:13px;color:var(--muted);margin-bottom:4px">最近录入</div>
    <ul class="list" id="recent"></ul>
  </div>
  <p class="hint">数据只发送到你的 Mac，不经过任何云端；删除本页不会影响已保存的记录。</p>
</div>
<div class="save-bar"><button class="save" id="save">保存</button></div>
<div class="toast" id="toast">已保存</div>
<script>
var KEY = new URLSearchParams(location.search).get('k') || '';
function withKey(url) {
  return url + (url.indexOf('?') < 0 ? '?' : '&') + 'k=' + encodeURIComponent(KEY);
}
var nameInput = document.getElementById('name');
var categorySelect = document.getElementById('category');
var locationInput = document.getElementById('location');
var quantityInput = document.getElementById('quantity');
var photoBox = document.getElementById('photos');
var photoInput = document.getElementById('photo-input');
var recentList = document.getElementById('recent');
var toast = document.getElementById('toast');
var saveButton = document.getElementById('save');
var photos = [];
var emojiByName = {};

fetch(withKey('/api/bootstrap')).then(function (response) {
  return response.json();
}).then(function (data) {
  (data.categories || []).forEach(function (category) {
    emojiByName[category.name] = category.emoji || '📦';
    var option = document.createElement('option');
    option.value = category.name;
    option.textContent = category.emoji + ' ' + category.name;
    categorySelect.appendChild(option);
  });
  if (data.quickCategory) categorySelect.value = data.quickCategory;
  if (data.quickLocation) locationInput.value = data.quickLocation;
  var locList = document.getElementById('loc-list');
  (data.locations || []).forEach(function (name) {
    var option = document.createElement('option');
    option.value = name;
    locList.appendChild(option);
  });
});

function renderPhotos() {
  photoBox.textContent = '';
  photos.forEach(function (dataURL, index) {
    var image = document.createElement('img');
    image.src = dataURL;
    image.addEventListener('click', function () {
      photos.splice(index, 1);
      renderPhotos();
    });
    photoBox.appendChild(image);
  });
  var add = document.createElement('div');
  add.className = 'add-photo';
  add.textContent = '＋';
  add.addEventListener('click', function () { photoInput.click(); });
  photoBox.appendChild(add);
}

photoInput.addEventListener('change', function () {
  var files = Array.prototype.slice.call(photoInput.files || []);
  files.forEach(function (file) {
    compress(file, function (dataURL) {
      photos.push(dataURL);
      renderPhotos();
    });
  });
  photoInput.value = '';
});

function compress(file, done) {
  var image = new Image();
  image.onload = function () {
    var maxSide = 1280;
    var scale = Math.min(1, maxSide / Math.max(image.width, image.height));
    var canvas = document.createElement('canvas');
    canvas.width = Math.round(image.width * scale);
    canvas.height = Math.round(image.height * scale);
    canvas.getContext('2d').drawImage(image, 0, 0, canvas.width, canvas.height);
    done(canvas.toDataURL('image/jpeg', 0.8));
    URL.revokeObjectURL(image.src);
  };
  image.src = URL.createObjectURL(file);
}

function showToast(text) {
  toast.textContent = text;
  toast.classList.add('show');
  setTimeout(function () { toast.classList.remove('show'); }, 1600);
}

function timeAgo(iso) {
  var then = new Date(iso).getTime();
  if (!then) return '';
  var minutes = Math.round((Date.now() - then) / 60000);
  if (minutes < 1) return '刚刚';
  if (minutes < 60) return minutes + ' 分钟前';
  var hours = Math.round(minutes / 60);
  if (hours < 24) return hours + ' 小时前';
  return Math.round(hours / 24) + ' 天前';
}

function loadRecent() {
  fetch(withKey('/api/recent')).then(function (response) {
    return response.json();
  }).then(function (data) {
    var items = data.items || [];
    recentList.textContent = '';
    items.forEach(function (item) {
      var li = document.createElement('li');
      var thumb = document.createElement('div');
      thumb.className = 'thumb';
      if (item.photos && item.photos.length) {
        var image = document.createElement('img');
        image.src = withKey('/api/photo/' + item.photos[0]);
        thumb.appendChild(image);
      } else {
        thumb.textContent = emojiByName[item.category] || '📦';
      }
      var meta = document.createElement('div');
      meta.className = 'meta';
      var name = document.createElement('div');
      name.className = 'name';
      name.textContent = item.name;
      var sub = document.createElement('div');
      sub.className = 'sub';
      sub.textContent = [item.category, item.location, '× ' + item.quantity, timeAgo(item.createdAt)]
        .filter(function (part) { return !!part; }).join(' · ');
      meta.appendChild(name);
      meta.appendChild(sub);
      li.appendChild(thumb);
      li.appendChild(meta);
      recentList.appendChild(li);
    });
    if (!items.length) {
      var empty = document.createElement('li');
      empty.className = 'empty';
      empty.textContent = '还没有记录';
      recentList.appendChild(empty);
    }
  });
}

saveButton.addEventListener('click', function () {
  var name = nameInput.value.trim();
  if (!name) { showToast('请填写名称'); nameInput.focus(); return; }
  saveButton.disabled = true;
  fetch(withKey('/api/items'), {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      name: name,
      category: categorySelect.value,
      location: locationInput.value.trim(),
      quantity: Math.max(1, parseInt(quantityInput.value, 10) || 1),
      photos: photos,
    }),
  }).then(function (response) {
    if (!response.ok) throw new Error('HTTP ' + response.status);
    return response.json();
  }).then(function () {
    showToast('已保存 ✓');
    nameInput.value = '';
    photos = [];
    renderPhotos();
    loadRecent();
    nameInput.focus();
  }).catch(function (error) {
    showToast('保存失败：' + error.message);
  }).then(function () {
    saveButton.disabled = false;
  });
});

renderPhotos();
loadRecent();
nameInput.focus();
</script>
</body>
</html>
"""##
}
