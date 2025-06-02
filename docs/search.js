class BlogSearch {
  constructor() {
    this.searchIndex = [];
  }

  async load() {
    try {
      const res = await fetch("search-index.json");
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      this.searchIndex = await res.json();
    } catch (err) {
      console.error("Error loading search index:", err);
      this.searchIndex = [];
    }
  }

  search(q, max = 10) {
    if (!q || q.length < 2) return [];
    const words = q.toLowerCase().split(/\s+/);
    return this.searchIndex.map(entry => {
      const title = (entry.title || "").toLowerCase();
      const content = (entry.content || "").toLowerCase();
      let score = 0;
      words.forEach(w => {
        if (title.includes(w)) score += 5;
        if (content.includes(w)) score += 1;
      });
      return { ...entry, score };
    }).filter(e => e.score > 0).sort((a, b) => b.score - a.score).slice(0, max);
  }

  highlight(text, query) {
    const words = query.split(/\s+/).filter(w => w.length > 1);
    let result = text;
    words.forEach(w => {
      const regex = new RegExp(`(${w.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')})`, 'gi');
      result = result.replace(regex, '<mark>$1</mark>');
    });
    return result;
  }

  snippet(content, query, len = 200) {
    if (!content || !query) return "";
    const lower = content.toLowerCase();
    const index = lower.indexOf(query.toLowerCase());
    const start = Math.max(0, index - len / 2);
    return content.substring(start, start + len).trim() + '...';
  }
}