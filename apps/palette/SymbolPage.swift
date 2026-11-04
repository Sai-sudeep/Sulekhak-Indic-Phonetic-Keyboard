import UIKit

/// The Unicode symbols page of the iPhone / iPad keyboard (the Ω button in the row above the suggestions): every category in its own row, each row scrolling sideways
/// on its own, the symbol large with its name under it. A tap types the real character at the cursor (a selection is replaced); a long press adds or removes a favourite.
/// Search (names and U+ codes) has a small keypad of its own, since a view inside a keyboard cannot take the text focus. palette.json is the list the web, Mac, Windows and
/// Android palettes use. A combining mark is drawn on a no-break space here and typed alone: no dotted circle is ever typed.
/// (A keyboard only appears when a text field is being edited, so on iOS a symbol is always typed; there is no clipboard case.)
final class SymbolPageView: UIView, UITableViewDataSource, UITableViewDelegate {
    struct Item {
        let cp: UInt32
        let name: String
        let abbr: String?
        let search: String
        var text: String { return String(UnicodeScalar(cp) ?? " ") }
        var hex: String { let h = String(cp, radix: 16, uppercase: true); return String(repeating: "0", count: max(0, 4 - h.count)) + h }
        var shown: String {
            if let a = abbr { return a }
            let s = text
            if let u = UnicodeScalar(cp) {
                switch u.properties.generalCategory {
                case .nonspacingMark, .spacingMark, .enclosingMark: return "\u{00A0}" + s
                default: break
                }
            }
            return s
        }
    }
    struct Section { let id: String; let title: String; var items: [Item] }

    var onSymbol: ((String) -> Void)?
    var onBack: (() -> Void)?
    var onBackspace: (() -> Void)?
    var onSpace: (() -> Void)?

    private let bg = UIColor { $0.userInterfaceStyle == .dark ? UIColor(white: 0.10, alpha: 1) : UIColor(white: 0.82, alpha: 1) }
    private let keyBg = UIColor { $0.userInterfaceStyle == .dark ? UIColor(white: 0.30, alpha: 1) : UIColor.white }
    private let fg = UIColor { $0.userInterfaceStyle == .dark ? UIColor.white : UIColor.black }
    private let dim = UIColor { $0.userInterfaceStyle == .dark ? UIColor(white: 0.70, alpha: 1) : UIColor(white: 0.35, alpha: 1) }
    private let accent = UIColor(red: 0.09, green: 0.28, blue: 0.37, alpha: 1)

    private var cats: [Section] = []
    private var all: [Item] = []
    private var byCp: [UInt32: Item] = [:]
    private var favs: [UInt32] = []
    private var recent: [UInt32] = []
    private var sections: [Section] = []
    private var loaded = false

    private let header = UIView()
    private let backBtn = UIButton(type: .custom), searchBtn = UIButton(type: .custom), spaceBtn = UIButton(type: .custom), delBtn = UIButton(type: .custom)
    private let status = UILabel()
    private let table = UITableView(frame: .zero, style: .plain)
    private let searchBox = UIView()
    private let queryLabel = UILabel()
    private let results = StripView()
    private let keypad = UIView()
    private var keyButtons: [UIButton] = []
    private var query = ""
    private var searching = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = bg
        loadData()
        loadLists()
        build()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    // MARK: data
    private func loadData() {
        guard let url = Bundle(for: SymbolPageView.self).url(forResource: "palette", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let cs = obj["cats"] as? [[String: Any]] else { return }
        for c in cs {
            guard let id = c["id"] as? String, let title = c["title"] as? String, let items = c["items"] as? [[Any]] else { continue }
            var list: [Item] = []
            for it in items {
                guard it.count >= 2, let n = it[0] as? NSNumber, let name = it[1] as? String else { continue }
                let cp = n.uint32Value
                let abbr = it.count > 2 ? it[2] as? String : nil
                var h = String(cp, radix: 16, uppercase: true); while h.count < 4 { h = "0" + h }
                let ch = String(UnicodeScalar(cp) ?? " ")
                let s = (name + " u+" + h + " " + h + " " + (abbr ?? "") + " " + title + " " + ch).lowercased()
                let item = Item(cp: cp, name: name, abbr: abbr, search: s)
                list.append(item); all.append(item)
                if byCp[cp] == nil { byCp[cp] = item }
            }
            cats.append(Section(id: id, title: title, items: list))
        }
        loaded = !all.isEmpty
    }

    private func loadLists() {
        func read(_ k: String) -> [UInt32] {
            let s = UserDefaults.standard.string(forKey: k) ?? ""
            var out: [UInt32] = []
            for p in s.split(separator: ",") { if let v = UInt32(p, radix: 16), byCp[v] != nil, !out.contains(v) { out.append(v) } }
            return out
        }
        favs = read("sulekhak.pal.fav"); recent = read("sulekhak.pal.recent")
    }
    private func save(_ k: String, _ l: [UInt32]) {
        UserDefaults.standard.set(l.map { String($0, radix: 16) }.joined(separator: ","), forKey: k)
    }

    private func rebuildSections() {
        sections = []
        let f = favs.compactMap { byCp[$0] }, r = recent.compactMap { byCp[$0] }
        if !f.isEmpty { sections.append(Section(id: "fav", title: "★ Favourites", items: f)) }
        if !r.isEmpty { sections.append(Section(id: "recent", title: "Recent", items: r)) }
        sections += cats.filter { !$0.items.isEmpty }
    }

    // MARK: layout
    private func styleButton(_ b: UIButton, _ t: String, accentOn: Bool = false) {
        b.setTitle(t, for: .normal)
        b.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        b.setTitleColor(accentOn ? accent : fg, for: .normal)
        b.layer.cornerRadius = 7
        b.backgroundColor = keyBg
    }

    private func build() {
        addSubview(header)
        styleButton(backBtn, "ABC", accentOn: true); backBtn.accessibilityLabel = "Back to the letters"
        backBtn.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        styleButton(searchBtn, "🔍"); searchBtn.accessibilityLabel = "Search symbols"
        searchBtn.addTarget(self, action: #selector(searchTapped), for: .touchUpInside)
        styleButton(spaceBtn, "␣"); spaceBtn.accessibilityLabel = "Space"
        spaceBtn.addTarget(self, action: #selector(spaceTapped), for: .touchUpInside)
        styleButton(delBtn, "⌫"); delBtn.accessibilityLabel = "Delete"
        delBtn.addTarget(self, action: #selector(delTapped), for: .touchUpInside)
        status.font = UIFont.systemFont(ofSize: 12); status.textColor = dim; status.text = "Tap: type · long press: favourite"
        status.adjustsFontSizeToFitWidth = true; status.minimumScaleFactor = 0.7
        for v in [backBtn, searchBtn, status, spaceBtn, delBtn] as [UIView] { header.addSubview(v) }

        table.dataSource = self; table.delegate = self
        table.backgroundColor = .clear; table.separatorStyle = .none
        table.showsVerticalScrollIndicator = false
        table.rowHeight = 78
        table.register(RowCell.self, forCellReuseIdentifier: "row")
        addSubview(table)

        searchBox.isHidden = true
        addSubview(searchBox)
        queryLabel.font = UIFont.systemFont(ofSize: 15); queryLabel.textColor = dim
        searchBox.addSubview(queryLabel)
        results.onTap = { [weak self] it in self?.chosen(it) }
        results.onHold = { [weak self] it in self?.toggleFavourite(it) }
        searchBox.addSubview(results)
        searchBox.addSubview(keypad)
        let rows = ["1234567890", "qwertyuiop", "asdfghjkl+", "zxcvbnm-U⌫"]
        for r in rows {
            for c in r {
                let b = UIButton(type: .custom)
                styleButton(b, c == "U" ? "U+" : String(c))
                b.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
                b.addTarget(self, action: #selector(keyTapped(_:)), for: .touchUpInside)
                keypad.addSubview(b); keyButtons.append(b)
            }
        }
        rebuildSections()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let w = bounds.width, h = bounds.height
        let hh: CGFloat = 40
        header.frame = CGRect(x: 0, y: 0, width: w, height: hh)
        backBtn.frame = CGRect(x: 6, y: 4, width: 56, height: hh - 8)
        searchBtn.frame = CGRect(x: 68, y: 4, width: 46, height: hh - 8)
        delBtn.frame = CGRect(x: w - 56, y: 4, width: 50, height: hh - 8)
        spaceBtn.frame = CGRect(x: w - 112, y: 4, width: 50, height: hh - 8)
        status.frame = CGRect(x: 122, y: 0, width: max(40, w - 122 - 118), height: hh)
        table.frame = CGRect(x: 0, y: hh, width: w, height: h - hh)
        searchBox.frame = CGRect(x: 0, y: hh, width: w, height: h - hh)
        queryLabel.frame = CGRect(x: 10, y: 0, width: w - 20, height: 28)
        results.frame = CGRect(x: 0, y: 28, width: w, height: 70)
        keypad.frame = CGRect(x: 0, y: 100, width: w, height: max(0, h - hh - 100))
        let rows = ["1234567890", "qwertyuiop", "asdfghjkl+", "zxcvbnm-U⌫"]
        var idx = 0
        let rh = keypad.bounds.height / 4
        for (ri, r) in rows.enumerated() {
            let n = CGFloat(r.count), kw = (w - 4 * (n + 1)) / n
            for ci in 0..<r.count {
                keyButtons[idx].frame = CGRect(x: 4 + CGFloat(ci) * (kw + 4), y: CGFloat(ri) * rh + 2, width: kw, height: rh - 4)
                idx += 1
            }
        }
    }

    /// The keyboard shows this page: back at the top, the favourites and recent rows as they now are.
    func willShow() {
        if searching { setSearching(false) }
        rebuildSections(); table.reloadData()
        table.setContentOffset(.zero, animated: false)
        status.text = "Tap: type · long press: favourite"
    }

    // MARK: table of rows
    func numberOfSections(in tableView: UITableView) -> Int { return 1 }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return sections.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "row", for: indexPath) as! RowCell
        let s = sections[indexPath.row]
        cell.titleLabel.text = s.title.uppercased()
        cell.titleLabel.textColor = dim
        cell.strip.set(s.items)
        cell.strip.colors(keyBg: keyBg, fg: fg, dim: dim, accent: accent)
        cell.strip.favs = Set(favs)
        cell.strip.onTap = { [weak self] it in self?.chosen(it) }
        cell.strip.onHold = { [weak self] it in self?.toggleFavourite(it) }
        return cell
    }

    // MARK: search
    @objc private func searchTapped() { setSearching(!searching) }
    private func setSearching(_ on: Bool) {
        searching = on
        table.isHidden = on; searchBox.isHidden = !on
        if on { query = ""; updateSearch() } else { rebuildSections(); table.reloadData() }
    }
    @objc private func keyTapped(_ b: UIButton) {
        guard let t = b.title(for: .normal) else { return }
        if t == "⌫" { if !query.isEmpty { query.removeLast() } }
        else if t == "U+" { query += "u+" }
        else { query += t }
        updateSearch()
    }
    private func updateSearch() {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        queryLabel.text = q.isEmpty ? "Type a name (arrow, alpha) or a code (u+2192)" : q
        queryLabel.textColor = q.isEmpty ? dim : fg
        var out: [Item] = []
        if !q.isEmpty {
            let toks = q.split(separator: " ").map(String.init)
            for it in all where toks.allSatisfy({ it.search.contains($0) }) { out.append(it); if out.count >= 300 { break } }
        }
        results.set(out)
        results.colors(keyBg: keyBg, fg: fg, dim: dim, accent: accent)
        results.favs = Set(favs)
        status.text = q.isEmpty ? "Search" : "\(out.count) found"
    }

    // MARK: choosing
    private func chosen(_ it: Item) {
        onSymbol?(it.text)
        recent.removeAll { $0 == it.cp }; recent.insert(it.cp, at: 0)
        if recent.count > 30 { recent.removeLast(recent.count - 30) }
        save("sulekhak.pal.recent", recent)
        status.text = "Typed U+" + it.hex
    }
    private func toggleFavourite(_ it: Item) {
        if let i = favs.firstIndex(of: it.cp) { favs.remove(at: i); status.text = "Removed from favourites" }
        else { favs.insert(it.cp, at: 0); if favs.count > 200 { favs.removeLast() }; status.text = "Added to favourites" }
        save("sulekhak.pal.fav", favs)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        if searching { results.favs = Set(favs); results.reload() } else { rebuildSections(); table.reloadData() }
    }

    @objc private func backTapped() { onBack?() }
    @objc private func spaceTapped() { onSpace?() }
    @objc private func delTapped() { onBackspace?() }

    // MARK: one row of cells that scrolls sideways by itself
    final class StripView: UIView, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
        var items: [Item] = []
        var favs: Set<UInt32> = []
        var onTap: ((Item) -> Void)?
        var onHold: ((Item) -> Void)?
        private var keyBg = UIColor.white, fg = UIColor.black, dim = UIColor.gray, accent = UIColor.blue
        private let cv: UICollectionView

        override init(frame: CGRect) {
            let l = UICollectionViewFlowLayout()
            l.scrollDirection = .horizontal
            l.itemSize = CGSize(width: 52, height: 58)
            l.minimumLineSpacing = 3; l.minimumInteritemSpacing = 0
            l.sectionInset = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
            cv = UICollectionView(frame: .zero, collectionViewLayout: l)
            super.init(frame: frame)
            cv.backgroundColor = .clear
            cv.showsHorizontalScrollIndicator = false
            cv.alwaysBounceHorizontal = true
            cv.dataSource = self
            cv.register(SymCell.self, forCellWithReuseIdentifier: "c")
            addSubview(cv)
            let hold = UILongPressGestureRecognizer(target: self, action: #selector(held(_:)))
            hold.minimumPressDuration = 0.5
            cv.addGestureRecognizer(hold)
            let tap = UITapGestureRecognizer(target: self, action: #selector(tapped(_:)))
            cv.addGestureRecognizer(tap)
        }
        required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

        override func layoutSubviews() { super.layoutSubviews(); cv.frame = bounds }
        func set(_ l: [Item]) { items = l; cv.reloadData(); cv.setContentOffset(.zero, animated: false) }
        func reload() { cv.reloadData() }
        func colors(keyBg k: UIColor, fg f: UIColor, dim d: UIColor, accent a: UIColor) { keyBg = k; fg = f; dim = d; accent = a }

        func collectionView(_ c: UICollectionView, numberOfItemsInSection section: Int) -> Int { return items.count }
        func collectionView(_ c: UICollectionView, cellForItemAt ip: IndexPath) -> UICollectionViewCell {
            let cell = c.dequeueReusableCell(withReuseIdentifier: "c", for: ip) as! SymCell
            let it = items[ip.item]
            cell.fill(it, keyBg: keyBg, fg: fg, dim: dim, accent: accent, fav: favs.contains(it.cp))
            return cell
        }
        @objc private func tapped(_ g: UITapGestureRecognizer) {
            if let ip = cv.indexPathForItem(at: g.location(in: cv)), ip.item < items.count { onTap?(items[ip.item]) }
        }
        @objc private func held(_ g: UILongPressGestureRecognizer) {
            guard g.state == .began else { return }
            if let ip = cv.indexPathForItem(at: g.location(in: cv)), ip.item < items.count { onHold?(items[ip.item]) }
        }
    }

    final class SymCell: UICollectionViewCell {
        private let glyph = UILabel(), nameL = UILabel(), star = UILabel()
        override init(frame: CGRect) {
            super.init(frame: frame)
            contentView.layer.cornerRadius = 6
            contentView.layer.borderWidth = 0.5
            glyph.textAlignment = .center; glyph.adjustsFontSizeToFitWidth = true; glyph.minimumScaleFactor = 0.5
            nameL.textAlignment = .center; nameL.numberOfLines = 3; nameL.font = UIFont.systemFont(ofSize: 8)
            star.text = "★"; star.font = UIFont.systemFont(ofSize: 9); star.textColor = UIColor(red: 0.82, green: 0.60, blue: 0.10, alpha: 1)
            contentView.addSubview(glyph); contentView.addSubview(nameL); contentView.addSubview(star)
        }
        required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }
        override func layoutSubviews() {
            super.layoutSubviews()
            let w = contentView.bounds.width
            glyph.frame = CGRect(x: 2, y: 2, width: w - 4, height: 26)
            nameL.frame = CGRect(x: 2, y: 29, width: w - 4, height: 28)
            star.frame = CGRect(x: w - 13, y: 1, width: 12, height: 11)
        }
        func fill(_ it: Item, keyBg: UIColor, fg: UIColor, dim: UIColor, accent: UIColor, fav: Bool) {
            contentView.backgroundColor = keyBg
            contentView.layer.borderColor = dim.withAlphaComponent(0.4).cgColor
            glyph.text = it.shown
            glyph.font = it.abbr != nil ? UIFont.systemFont(ofSize: 11, weight: .bold) : UIFont.systemFont(ofSize: 22)
            glyph.textColor = it.abbr != nil ? accent : fg
            nameL.text = it.name; nameL.textColor = dim
            star.isHidden = !fav
        }
    }

    final class RowCell: UITableViewCell {
        let titleLabel = UILabel()
        let strip = StripView()
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            backgroundColor = .clear; selectionStyle = .none
            titleLabel.font = UIFont.systemFont(ofSize: 10, weight: .bold)
            contentView.addSubview(titleLabel); contentView.addSubview(strip)
        }
        required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }
        override func layoutSubviews() {
            super.layoutSubviews()
            titleLabel.frame = CGRect(x: 10, y: 3, width: contentView.bounds.width - 20, height: 14)
            strip.frame = CGRect(x: 0, y: 18, width: contentView.bounds.width, height: 60)
        }
    }
}
