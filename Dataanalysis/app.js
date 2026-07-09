// ===================================================================
//  LUA PARSER (WoW SavedVariables format)
// ===================================================================
function parseLuaSavedVars(text) {
    text = text.replace(/^\uFEFF/, '').replace(/\r\n?/g, '\n');

    // Strip multi-line comments: --[[ ... ]]
    text = text.replace(/--\[\[[\s\S]*?\]\]--?/g, '');
    text = text.replace(/--\[\[[\s\S]*?\]\]/g, '');
    let lines = text.split('\n');
    let cleaned = [];
    for (let line of lines) {
        let idx = line.indexOf('--');
        if (idx >= 0) {
            let inStr = false, strChar = null;
            for (let i = 0; i < idx; i++) {
                let ch = line[i];
                if (inStr) {
                    if (ch === '\\') { i++; continue; }
                    if (ch === strChar) inStr = false;
                } else if (ch === '"' || ch === "'") {
                    inStr = true;
                    strChar = ch;
                }
            }
            if (!inStr) line = line.substring(0, idx);
        }
        cleaned.push(line);
    }
    text = cleaned.join('\n');

    // Tokenizer
    let pos = 0;
    let tokens = [];

    const isIdent = (ch) => /[a-zA-Z_]/.test(ch);
    const isIdentCont = (ch) => /[a-zA-Z0-9_]/.test(ch);

    while (pos < text.length) {
        let ch = text[pos];
        if (ch === ' ' || ch === '\t' || ch === '\n' || ch === '\r') { pos++; continue; }

        if (ch === '"' || ch === "'") {
            let quote = ch;
            pos++;
            let str = '';
            while (pos < text.length) {
                let c = text[pos];
                if (c === '\\') {
                    pos++;
                    let esc = text[pos];
                    if (esc === 'n') str += '\n';
                    else if (esc === 't') str += '\t';
                    else if (esc === 'r') str += '\r';
                    else if (esc === '"') str += '"';
                    else if (esc === "'") str += "'";
                    else if (esc === '\\') str += '\\';
                    else str += '\\' + (esc || '');
                    pos++;
                } else if (c === quote) {
                    pos++;
                    break;
                } else {
                    str += c;
                    pos++;
                }
            }
            tokens.push({ type: 'STRING', value: str });
            continue;
        }

        if (ch === '[' && text[pos+1] === '[') {
            pos += 2;
            let str = '';
            while (pos < text.length - 1) {
                if (text[pos] === ']' && text[pos+1] === ']') {
                    pos += 2;
                    break;
                }
                str += text[pos];
                pos++;
            }
            tokens.push({ type: 'STRING', value: str });
            continue;
        }

        if (ch === '-' && text[pos+1] === '-') {
            let end = text.indexOf('\n', pos);
            if (end < 0) end = text.length;
            pos = end;
            continue;
        }

        if (ch === '{') { tokens.push({ type: '{' }); pos++; continue; }
        if (ch === '}') { tokens.push({ type: '}' }); pos++; continue; }
        if (ch === '[') { tokens.push({ type: '[' }); pos++; continue; }
        if (ch === ']') { tokens.push({ type: ']' }); pos++; continue; }
        if (ch === '=') { tokens.push({ type: '=' }); pos++; continue; }
        if (ch === ',') { tokens.push({ type: ',' }); pos++; continue; }
        if (ch === ';') { tokens.push({ type: ',' }); pos++; continue; }
        if (ch === '(') { tokens.push({ type: '(' }); pos++; continue; }
        if (ch === ')') { tokens.push({ type: ')' }); pos++; continue; }

        if (/[0-9]/.test(ch) || (ch === '.' && text[pos+1] && /[0-9]/.test(text[pos+1]))) {
            let start = pos;
            if (ch === '0' && (text[pos+1] === 'x' || text[pos+1] === 'X')) {
                pos += 2;
                while (pos < text.length && /[0-9a-fA-F]/.test(text[pos])) pos++;
                tokens.push({ type: 'NUMBER', value: parseInt(text.substring(start, pos), 16) });
                continue;
            }
            while (pos < text.length && /[0-9]/.test(text[pos])) pos++;
            if (text[pos] === '.' && text[pos+1] && /[0-9]/.test(text[pos+1])) {
                pos++;
                while (pos < text.length && /[0-9]/.test(text[pos])) pos++;
            }
            if ((text[pos] === 'e' || text[pos] === 'E') && text[pos+1]) {
                pos++;
                if (text[pos] === '+' || text[pos] === '-') pos++;
                while (pos < text.length && /[0-9]/.test(text[pos])) pos++;
            }
            tokens.push({ type: 'NUMBER', value: parseFloat(text.substring(start, pos)) });
            continue;
        }

        if (isIdent(ch)) {
            let start = pos;
            while (pos < text.length && isIdentCont(text[pos])) pos++;
            let word = text.substring(start, pos);
            if (word === 'true') tokens.push({ type: 'TRUE' });
            else if (word === 'false') tokens.push({ type: 'FALSE' });
            else if (word === 'nil') tokens.push({ type: 'NIL' });
            else tokens.push({ type: 'IDENT', value: word });
            continue;
        }

        pos++;
    }

    // Parser
    let idx = 0;
    function peek() { return tokens[idx]; }
    function consume() { return tokens[idx++]; }
    function expect(type) {
        let t = consume();
        if (!t || t.type !== type) throw new Error('Expected ' + type + ', got ' + (t ? t.type : 'EOF'));
        return t;
    }

    function parseValue() {
        let t = peek();
        if (!t) throw new Error('Unexpected EOF');
        if (t.type === '{') return parseTable();
        if (t.type === 'STRING') return consume().value;
        if (t.type === 'NUMBER') return consume().value;
        if (t.type === 'TRUE') { consume(); return true; }
        if (t.type === 'FALSE') { consume(); return false; }
        if (t.type === 'NIL') { consume(); return null; }
        if (t.type === 'IDENT') return consume().value;
        if (t.type === '(') {
            consume();
            let val = parseValue();
            expect(')');
            return val;
        }
        if (t.type === '-' || t.type === '+') {
            let sign = consume().type === '-' ? -1 : 1;
            let num = expect('NUMBER');
            return sign * num.value;
        }
        throw new Error('Unexpected token ' + t.type + ' at value position');
    }

    function parseTable() {
        expect('{');
        let result = {};
        let arrayMode = null;
        let nextIndex = 1;

        while (peek() && peek().type !== '}') {
            if (peek().type === '[') {
                consume();
                let key = parseValue();
                expect(']');
                expect('=');
                let val = parseValue();
                if (typeof key === 'number') {
                    result[key] = val;
                } else {
                    result[String(key)] = val;
                }
                if (arrayMode === null) arrayMode = false;
                if (peek() && (peek().type === ',' || peek().type === ';')) consume();
                continue;
            }

            let saved = idx;
            let t = consume();
            if (t.type === 'IDENT' && peek() && peek().type === '=') {
                consume();
                let val = parseValue();
                result[t.value] = val;
                if (arrayMode === null) arrayMode = false;
            } else {
                idx = saved;
                let val = parseValue();
                result[nextIndex] = val;
                nextIndex++;
                if (arrayMode === null) arrayMode = true;
            }

            if (peek() && (peek().type === ',' || peek().type === ';')) consume();
        }

        expect('}');

        if (arrayMode === true) {
            let arr = [];
            for (let i = 1; i < nextIndex; i++) {
                if (result[i] !== undefined) arr.push(result[i]);
            }
            let extraKeys = Object.keys(result).filter(function(k) {
                return isNaN(Number(k)) || Number(k) < 1 || Number(k) >= nextIndex;
            });
            if (extraKeys.length === 0 && arr.length > 0) return arr;
            if (extraKeys.length === 0 && arr.length === 0) return [];
        }

        return result;
    }

    let found = false;
    let result = null;
    while (idx < tokens.length) {
        if (peek() && peek().type === 'IDENT' && peek().value === 'DetaurBarDB') {
            consume();
            if (peek() && peek().type === '=') {
                consume();
                result = parseValue();
                found = true;
                break;
            }
        } else {
            consume();
        }
    }

    if (!found) throw new Error('Could not find DetaurBarDB = {...} in file');
    return result;
}

// ===================================================================
//  APP
// ===================================================================
let data = null;
let selectedItemId = null;
let selectedFaction = 'Horde';

const fileInput = document.getElementById('fileInput');
const status = document.getElementById('status');
const placeholder = document.getElementById('placeholder');
const itemList = document.getElementById('itemList');
const searchBox = document.getElementById('searchBox');
const detailBar = document.getElementById('detailBar');
const chartWrap = document.getElementById('chartWrap');
const chartControls = document.getElementById('chartControls');
const canvas = document.getElementById('chartCanvas');
const ctx = canvas.getContext('2d');
const tooltip = document.getElementById('chartTooltip');
const chartInfo = document.getElementById('chartInfo');

fileInput.addEventListener('change', function(e) {
    let file = e.target.files[0];
    if (!file) return;
    let reader = new FileReader();
    reader.onload = function(ev) {
        try {
            data = parseLuaSavedVars(ev.target.result);
            status.textContent = 'loaded: ' + file.name;
            status.className = 'loaded';
            renderItemList();
            placeholder.style.display = 'none';
        } catch (err) {
            status.textContent = 'parse error: ' + err.message;
            status.className = '';
            console.error(err);
        }
    };
    reader.readAsText(file);
});

searchBox.addEventListener('input', renderItemList);

// ===================================================================
//  ITEM LIST
// ===================================================================
function getAllItems() {
    if (!data || !data.price) return [];
    let items = [];
    if (Array.isArray(data.price)) {
        for (let item of data.price) {
            if (item && typeof item === 'object' && item.title) {
                items.push(item);
            }
        }
    } else {
        for (let faction of Object.keys(data.price)) {
            let list = data.price[faction];
            if (Array.isArray(list)) {
                for (let item of list) {
                    if (item && typeof item === 'object' && item.title) {
                        item._faction = faction;
                        items.push(item);
                    }
                }
            }
        }
    }
    return items;
}

function extractItemId(item) {
    if (!item.title) return null;
    // "item:49634"
    let m = item.title.match(/^item:(\d+)$/);
    if (m) return m[1];
    // "|cffffffff|Hitem:49633:..."
    m = item.title.match(/\|Hitem:(\d+):/);
    if (m) return m[1];
    return null;
}

function getPriceHistory(itemId, faction) {
    if (!data || !data.priceHistory) return null;
    let key = itemId + ':' + faction;
    return data.priceHistory[key];
}

function extractItemName(item) {
    if (item.name) return item.name;
    if (!item.title) return 'Unknown';

    // Try link format: |c...|Hitem:...|h[Name]|h|r
    let m = item.title.match(/\[([^\]]+)\]/);
    if (m) return m[1];

    // Try item:ID format and look up in offline database
    m = item.title.match(/^item:(\d+)$/);
    if (m) {
        let name = itemNames && itemNames[m[1]];
        if (name) return name;
        return 'Item #' + m[1];
    }

    return item.title;
}

function renderItemList() {
    let items = getAllItems();
    let query = searchBox.value.toLowerCase().trim();

    let groups = {};
    for (let item of items) {
        let faction = item._faction || 'General';
        if (!groups[faction]) groups[faction] = [];
        let name = extractItemName(item);
        let id = extractItemId(item);
        let match = !query || name.toLowerCase().includes(query) || (id && id.includes(query));
        if (match) groups[faction].push(item);
    }

    let html = '';
    let sortedFactions = Object.keys(groups).sort();
    for (let faction of sortedFactions) {
        let groupItems = groups[faction];
        html += '<div class="faction-header">' + faction + ' (' + groupItems.length + ')</div>';
        for (let item of groupItems) {
            let id = extractItemId(item);
            let name = extractItemName(item);
            let isActive = (id === selectedItemId);
            let f = item._faction || 'Horde';
            let thresh = item.threshold ? formatGold(item.threshold) : '';
            let freq = item.frequent ? '★' : '';
            html += '<div class="item-row' + (isActive ? ' active' : '') + '" data-id="' + id + '" data-faction="' + f + '">'
                + '<span class="name">' + escHtml(name) + '</span>'
                + '<span class="id-tag">#' + id + '</span>'
                + (thresh ? '<span class="thresh">' + escHtml(thresh) + '</span>' : '')
                + (freq ? '<span class="freq">' + freq + '</span>' : '')
                + '</div>';
        }
    }
    itemList.innerHTML = html;

    itemList.querySelectorAll('.item-row').forEach(function(el) {
        el.addEventListener('click', function() {
            selectItem(this.dataset.id, this.dataset.faction);
        });
    });
}

function selectItem(itemId, faction) {
    selectedItemId = itemId;
    selectedFaction = faction || 'Horde';
    renderItemList();

    let items = getAllItems();
    let item = items.find(function(i) { return extractItemId(i) === itemId; });
    if (!item) return;

    let history = getPriceHistory(itemId, faction || item._faction || 'Horde');
    if (!history || Object.keys(history).length === 0) {
        detailBar.classList.remove('visible');
        chartWrap.classList.remove('visible');
        chartControls.style.display = 'none';
        return;
    }

    let id = extractItemId(item);
    let name = extractItemName(item);
    let thresh = item.threshold ? formatGold(item.threshold) : 'no threshold';
    let freq = item.frequent ? 'Frequent' : '';

    document.getElementById('dName').textContent = name;
    document.getElementById('dId').textContent = '#' + id;
    document.getElementById('dThresh').textContent = 'Threshold: ' + thresh;
    document.getElementById('dCount').textContent = Object.keys(history).length + ' data points';
    document.getElementById('dFreq').textContent = freq;

    detailBar.classList.add('visible');
    chartWrap.classList.add('visible');
    chartControls.style.display = 'flex';

    drawChart(itemId, 'D');
}

// ===================================================================
//  FORMAT HELPERS
// ===================================================================
function formatGold(copper) {
    if (copper == null || copper === 0) return '0g';
    let g = Math.floor(copper / 10000);
    let s = Math.floor((copper % 10000) / 100);
    let c = copper % 100;
    let parts = [];
    if (g > 0) parts.push(g + 'g');
    if (s > 0) parts.push(s + 's');
    if (c > 0 || parts.length === 0) parts.push(c + 'c');
    return parts.join(' ');
}

function formatDate(ts) {
    let d = new Date(Number(ts) * 1000);
    let pad = function(n) { return String(n).padStart(2, '0'); };
    return pad(d.getDate()) + '/' + pad(d.getMonth()+1) + ' ' + pad(d.getHours()) + ':' + pad(d.getMinutes());
}

function escHtml(s) {
    let d = document.createElement('div');
    d.textContent = s;
    return d.innerHTML;
}

// ===================================================================
//  CHART
// ===================================================================
let _chartPeriod = 'D';
let _chartData = [];

document.querySelectorAll('.chart-controls button[data-period]').forEach(function(btn) {
    btn.addEventListener('click', function() {
        document.querySelectorAll('.chart-controls button[data-period]').forEach(function(b) { b.classList.remove('active'); });
        this.classList.add('active');
        _chartPeriod = this.dataset.period;
        if (selectedItemId) drawChart(selectedItemId, _chartPeriod);
    });
});

function drawChart(itemId, period) {
    let history = getPriceHistory(itemId, selectedFaction);
    if (!history) return;

    let points = Object.entries(history)
        .map(function(e) { return { ts: Number(e[0]), val: Number(e[1]) }; })
        .sort(function(a, b) { return a.ts - b.ts; });

    if (points.length === 0) return;

    let now = Date.now() / 1000;
    let cutoff = 0;
    if (period === 'D') cutoff = now - 86400;
    else if (period === 'W') cutoff = now - 7 * 86400;
    else if (period === 'M') cutoff = now - 30 * 86400;
    else if (period === 'Y') cutoff = now - 365 * 86400;
    else cutoff = 0;

    let filtered = cutoff > 0 ? points.filter(function(p) { return p.ts >= cutoff; }) : points;
    if (filtered.length < 2) filtered = points;

    _chartData = filtered;

    let count = filtered.length;
    let minTs = filtered[0].ts;
    let maxTs = filtered[count-1].ts;
    let vals = filtered.map(function(p) { return p.val; });
    let minVal = Math.min.apply(null, vals);
    let maxVal = Math.max.apply(null, vals);
    if (minVal === maxVal) { minVal = minVal * 0.9; maxVal = maxVal * 1.1; }
    if (minVal < 0) minVal = 0;

    chartInfo.textContent = count + ' points | ' + formatGold(minVal) + ' \u2013 ' + formatGold(maxVal);

    let rect = chartWrap.getBoundingClientRect();
    let dpr = window.devicePixelRatio || 1;
    let w = Math.max(rect.width - 2, 200);
    let h = Math.max(rect.height - 2, 100);
    canvas.width = w * dpr;
    canvas.height = h * dpr;
    canvas.style.width = w + 'px';
    canvas.style.height = h + 'px';
    ctx.scale(dpr, dpr);

    let pad = { top: 20, right: 16, bottom: 36, left: 56 };
    let cw = w - pad.left - pad.right;
    let ch = h - pad.top - pad.bottom;

    ctx.clearRect(0, 0, w, h);

    ctx.fillStyle = '#0e0c0a';
    ctx.fillRect(0, 0, w, h);

    function mapX(ts) { return pad.left + ((ts - minTs) / (maxTs - minTs)) * cw; }
    function mapY(val) { return pad.top + (1 - (val - minVal) / (maxVal - minVal)) * ch; }

    ctx.strokeStyle = '#1a1814';
    ctx.lineWidth = 1;
    for (let i = 0; i <= 4; i++) {
        let y = pad.top + (i / 4) * ch;
        ctx.beginPath();
        ctx.moveTo(pad.left, y);
        ctx.lineTo(pad.left + cw, y);
        ctx.stroke();
    }

    ctx.fillStyle = '#6a5a48';
    ctx.font = '11px sans-serif';
    ctx.textAlign = 'right';
    ctx.textBaseline = 'middle';
    for (let i = 0; i <= 4; i++) {
        let val = minVal + (maxVal - minVal) * (1 - i / 4);
        let y = pad.top + (i / 4) * ch;
        ctx.fillText(formatGold(Math.round(val)), pad.left - 6, y);
    }

    ctx.textAlign = 'center';
    ctx.textBaseline = 'top';
    for (let i = 0; i <= 2; i++) {
        let ts = minTs + (maxTs - minTs) * (i / 2);
        let x = mapX(ts);
        ctx.fillText(formatDate(ts), x, pad.top + ch + 8);
    }

    ctx.strokeStyle = '#1a1814';
    for (let i = 0; i <= 2; i++) {
        let ts = minTs + (maxTs - minTs) * (i / 2);
        let x = mapX(ts);
        ctx.beginPath();
        ctx.moveTo(x, pad.top);
        ctx.lineTo(x, pad.top + ch);
        ctx.stroke();
    }

    if (filtered.length < 2) return;
    ctx.strokeStyle = '#f0d878';
    ctx.lineWidth = 2;
    ctx.beginPath();
    for (let i = 0; i < filtered.length; i++) {
        let x = mapX(filtered[i].ts);
        let y = mapY(filtered[i].val);
        if (i === 0) ctx.moveTo(x, y);
        else ctx.lineTo(x, y);
    }
    ctx.stroke();

    let maxDots = 200;
    let step = Math.max(1, Math.floor(filtered.length / maxDots));
    ctx.fillStyle = '#f0d878';
    for (let i = 0; i < filtered.length; i += step) {
        let x = mapX(filtered[i].ts);
        let y = mapY(filtered[i].val);
        ctx.beginPath();
        ctx.arc(x, y, 3, 0, Math.PI * 2);
        ctx.fill();
    }

    canvas._points = filtered.map(function(p) { return { x: mapX(p.ts), y: mapY(p.val), ts: p.ts, val: p.val }; });
}

// ===================================================================
//  CHART TOOLTIP
// ===================================================================
canvas.addEventListener('mousemove', function(e) {
    if (!canvas._points) return;
    let rect = canvas.getBoundingClientRect();
    let mx = e.clientX - rect.left;
    let my = e.clientY - rect.top;

    let minDist = Infinity;
    let nearest = null;
    for (let p of canvas._points) {
        let dx = mx - p.x;
        let dy = my - p.y;
        let dist = dx * dx + dy * dy;
        if (dist < minDist && dist < 400) {
            minDist = dist;
            nearest = p;
        }
    }

    if (nearest) {
        let d = new Date(nearest.ts * 1000);
        let dateStr = d.toLocaleString();
        tooltip.innerHTML = '<b>' + formatGold(nearest.val) + '</b><br><span style="color:#8a7a60">' + dateStr + '</span>';
        tooltip.style.left = Math.min(nearest.x + 12, canvas.width - 160) + 'px';
        tooltip.style.top = Math.max(nearest.y - 20, 4) + 'px';
        tooltip.classList.add('visible');
    } else {
        tooltip.classList.remove('visible');
    }
});

canvas.addEventListener('mouseleave', function() {
    tooltip.classList.remove('visible');
});

// ===================================================================
//  RESIZE
// ===================================================================
let resizeTimer;
window.addEventListener('resize', function() {
    clearTimeout(resizeTimer);
    resizeTimer = setTimeout(function() {
        if (selectedItemId) drawChart(selectedItemId, _chartPeriod);
    }, 200);
});

const resizeObserver = new ResizeObserver(function() {
    if (selectedItemId) drawChart(selectedItemId, _chartPeriod);
});
resizeObserver.observe(chartWrap);

console.log('DetaurBar Price Viewer ready. Load a SavedVariables file to begin.');
