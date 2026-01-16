pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.functions
import qs.services
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Service for fetching random wallpapers from various online sources.
 */
Singleton {
    id: root

    // Configuration
    property string downloadDir: FileUtils.trimFileProtocol(`${Directories.pictures}/NetworkWallpapers`)
    property string currentSource: "wallhaven"
    property bool loading: false
    property string lastError: ""
    property string lastDownloadedPath: ""

    // Resolution settings (minimum resolution filter)
    property int minWidth: Config.options?.wallpaper?.minWidth ?? 2880
    property int minHeight: Config.options?.wallpaper?.minHeight ?? 1800

    // API Keys (optional - set in config)
    property string wallhavenApiKey: Config.options?.wallpaper?.wallhavenApiKey ?? ""

    // Wallhaven settings
    property string wallhavenCategories: "111"  // general/anime/people
    property string wallhavenPurity: "100"      // sfw only
    property bool nsfwEnabled: false            // NSFW toggle

    signal wallpaperReady(string path)
    signal errorOccurred(string message)

    readonly property var sources: ({
        "wallhaven": {
            "name": "Wallhaven",
            "description": "High-quality wallpapers, all categories"
        },
        "anime": {
            "name": "Anime",
            "description": "Anime wallpapers from Wallhaven"
        },
        "danbooru": {
            "name": "Danbooru",
            "description": "Anime imageboard, high quality"
        },
        "konachan": {
            "name": "Konachan",
            "description": "Anime wallpapers imageboard"
        },
        "gelbooru": {
            "name": "Gelbooru",
            "description": "Large anime imageboard"
        },
        "safebooru": {
            "name": "Safebooru",
            "description": "SFW anime imageboard"
        },
        "picre": {
            "name": "pic.re",
            "description": "Random anime from Pixiv"
        },
        "waifu": {
            "name": "Waifu.im",
            "description": "Anime wallpapers, landscape"
        },
        "reddit": {
            "name": "Reddit",
            "description": "r/wallpapers community"
        },
        "animewallpaper": {
            "name": "r/Animewallpaper",
            "description": "Reddit anime wallpapers"
        },
        "widescreen": {
            "name": "Widescreen",
            "description": "r/WidescreenWallpaper ultrawide"
        },
        "minimal": {
            "name": "Minimal",
            "description": "r/MinimalWallpaper clean designs"
        }
    })

    readonly property var sourceList: Object.keys(sources)

    Component.onCompleted: {
        ensureDirProc.running = true
    }

    Process {
        id: ensureDirProc
        command: ["mkdir", "-p", root.downloadDir]
    }

    function setSource(source) {
        source = source.toLowerCase()
        if (sourceList.indexOf(source) !== -1) {
            root.currentSource = source
            print("[RandomNetworkWallpaper] Source set to:", sources[source].name)
            return true
        }
        print("[RandomNetworkWallpaper] Invalid source. Available:", sourceList.join(", "))
        return false
    }

    function fetchRandom(source) {
        if (source) setSource(source)
        
        if (root.loading) {
            print("[RandomNetworkWallpaper] Already loading, please wait...")
            return
        }

        root.loading = true
        root.lastError = ""

        switch (root.currentSource) {
            case "wallhaven":
                fetchWallhaven(false)
                break
            case "anime":
                fetchWallhaven(true)
                break
            case "danbooru":
                fetchDanbooru()
                break
            case "konachan":
                fetchKonachan()
                break
            case "gelbooru":
                fetchGelbooru()
                break
            case "safebooru":
                fetchSafebooru()
                break
            case "picre":
                fetchPicRe()
                break
            case "waifu":
                fetchWaifuIm()
                break
            case "reddit":
                fetchRedditSubreddit("wallpapers")
                break
            case "animewallpaper":
                fetchRedditSubreddit("Animewallpaper")
                break
            case "widescreen":
                fetchRedditSubreddit("WidescreenWallpaper")
                break
            case "minimal":
                fetchRedditSubreddit("MinimalWallpaper")
                break
            default:
                handleError("Unknown source: " + root.currentSource)
        }
    }

    function handleError(message) {
        root.lastError = message
        root.loading = false
        print("[RandomNetworkWallpaper] Error:", message)
        root.errorOccurred(message)
    }

    function handleSuccess(path) {
        root.lastDownloadedPath = path
        root.loading = false
        print("[RandomNetworkWallpaper] Wallpaper ready:", path)
        root.wallpaperReady(path)
    }

    // ========================
    // WALLHAVEN
    // ========================
    function fetchWallhaven(animeOnly) {
        const categories = animeOnly ? "010" : wallhavenCategories
        const purity = nsfwEnabled ? (wallhavenApiKey ? "111" : "110") : "100"
        const params = [
            "sorting=random",
            `categories=${categories}`,
            `purity=${purity}`,
            `atleast=${minWidth}x${minHeight}`
        ]
        if (wallhavenApiKey) params.push(`apikey=${wallhavenApiKey}`)
        
        const url = `https://wallhaven.cc/api/v1/search?${params.join("&")}`
        print("[RandomNetworkWallpaper] Fetching from Wallhaven:", url)
        
        const xhr = new XMLHttpRequest()
        xhr.open("GET", url)
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        const response = JSON.parse(xhr.responseText)
                        if (response.data && response.data.length > 0) {
                            const wallpaper = response.data[Math.floor(Math.random() * response.data.length)]
                            downloadImage(wallpaper.path, `wallhaven-${wallpaper.id}`)
                        } else {
                            handleError("No wallpapers found on Wallhaven")
                        }
                    } catch (e) {
                        handleError("Failed to parse Wallhaven response: " + e)
                    }
                } else {
                    handleError(`Wallhaven request failed: ${xhr.status}`)
                }
            }
        }
        xhr.send()
    }

    // ========================
    // DANBOORU
    // ========================
    function fetchDanbooru() {
        // Rating: g=general, s=sensitive, q=questionable, e=explicit
        const rating = nsfwEnabled ? "" : "+rating:g,s"
        const url = `https://danbooru.donmai.us/posts.json?limit=50&tags=highres${rating}`
        print("[RandomNetworkWallpaper] Fetching from Danbooru")

        const xhr = new XMLHttpRequest()
        xhr.open("GET", url)
        xhr.setRequestHeader("User-Agent", "QuickShell-Wallpaper/1.0")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        const response = JSON.parse(xhr.responseText)
                        // Filter for images with sufficient resolution
                        const posts = response.filter(post => 
                            post.file_url && 
                            post.image_width >= root.minWidth &&
                            post.image_height >= root.minHeight
                        )
                        if (posts.length > 0) {
                            const post = posts[Math.floor(Math.random() * posts.length)]
                            downloadImage(post.file_url, `danbooru-${post.id}`)
                        } else {
                            handleError("No suitable images found on Danbooru")
                        }
                    } catch (e) {
                        handleError("Failed to parse Danbooru response: " + e)
                    }
                } else {
                    handleError(`Danbooru request failed: ${xhr.status}`)
                }
            }
        }
        xhr.send()
    }

    // ========================
    // KONACHAN
    // ========================
    function fetchKonachan() {
        // Konachan rating: s=safe, q=questionable, e=explicit
        const rating = nsfwEnabled ? "" : "+rating:s"
        const url = `https://konachan.net/post.json?limit=50&tags=width:>=${minWidth}+height:>=${minHeight}${rating}`
        print("[RandomNetworkWallpaper] Fetching from Konachan")

        const xhr = new XMLHttpRequest()
        xhr.open("GET", url)
        xhr.setRequestHeader("User-Agent", "QuickShell-Wallpaper/1.0")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        const response = JSON.parse(xhr.responseText)
                        if (response && response.length > 0) {
                            const post = response[Math.floor(Math.random() * response.length)]
                            const imageUrl = post.file_url || post.jpeg_url
                            if (imageUrl) {
                                downloadImage(imageUrl, `konachan-${post.id}`)
                            } else {
                                handleError("No image URL in Konachan response")
                            }
                        } else {
                            handleError("No images found on Konachan")
                        }
                    } catch (e) {
                        handleError("Failed to parse Konachan response: " + e)
                    }
                } else {
                    handleError(`Konachan request failed: ${xhr.status}`)
                }
            }
        }
        xhr.send()
    }

    // ========================
    // GELBOORU
    // ========================
    function fetchGelbooru() {
        // Gelbooru rating: general, sensitive, questionable, explicit
        const rating = nsfwEnabled ? "" : "+rating:general"
        const url = `https://gelbooru.com/index.php?page=dapi&s=post&q=index&json=1&limit=50&tags=highres${rating}+sort:random`
        print("[RandomNetworkWallpaper] Fetching from Gelbooru")

        const xhr = new XMLHttpRequest()
        xhr.open("GET", url)
        xhr.setRequestHeader("User-Agent", "QuickShell-Wallpaper/1.0")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        const response = JSON.parse(xhr.responseText)
                        const posts = (response.post || []).filter(post =>
                            post.file_url &&
                            post.width >= root.minWidth &&
                            post.height >= root.minHeight
                        )
                        if (posts.length > 0) {
                            const post = posts[Math.floor(Math.random() * posts.length)]
                            downloadImage(post.file_url, `gelbooru-${post.id}`)
                        } else {
                            handleError("No suitable images found on Gelbooru")
                        }
                    } catch (e) {
                        handleError("Failed to parse Gelbooru response: " + e)
                    }
                } else {
                    handleError(`Gelbooru request failed: ${xhr.status}`)
                }
            }
        }
        xhr.send()
    }

    // ========================
    // SAFEBOORU
    // ========================
    function fetchSafebooru() {
        const url = `https://safebooru.org/index.php?page=dapi&s=post&q=index&json=1&limit=50&tags=highres`
        print("[RandomNetworkWallpaper] Fetching from Safebooru")

        const xhr = new XMLHttpRequest()
        xhr.open("GET", url)
        xhr.setRequestHeader("User-Agent", "QuickShell-Wallpaper/1.0")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        const response = JSON.parse(xhr.responseText)
                        const posts = (response || []).filter(post =>
                            post.file_url &&
                            post.width >= root.minWidth &&
                            post.height >= root.minHeight
                        )
                        if (posts.length > 0) {
                            const post = posts[Math.floor(Math.random() * posts.length)]
                            downloadImage(post.file_url, `safebooru-${post.id}`)
                        } else {
                            handleError("No suitable images found on Safebooru")
                        }
                    } catch (e) {
                        handleError("Failed to parse Safebooru response: " + e)
                    }
                } else {
                    handleError(`Safebooru request failed: ${xhr.status}`)
                }
            }
        }
        xhr.send()
    }

    // ========================
    // PIC.RE
    // ========================
    function fetchPicRe() {
        print("[RandomNetworkWallpaper] Fetching from pic.re")
        picreProc.exec(["curl", "-sI", "https://pic.re/image"])
    }

    Process {
        id: picreProc
        
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n")
                let imageId = Date.now().toString()
                for (const line of lines) {
                    if (line.toLowerCase().startsWith("image_id:")) {
                        imageId = line.split(":")[1].trim()
                        break
                    }
                }
                root.downloadImage("https://pic.re/image", `picre-${imageId}`)
            }
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                root.handleError("pic.re request failed")
            }
        }
    }

    // ========================
    // WAIFU.IM
    // ========================
    function fetchWaifuIm() {
        const nsfw = nsfwEnabled ? "true" : "false"
        const url = `https://api.waifu.im/search?is_nsfw=${nsfw}&orientation=LANDSCAPE`
        print("[RandomNetworkWallpaper] Fetching from Waifu.im")

        const xhr = new XMLHttpRequest()
        xhr.open("GET", url)
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        const response = JSON.parse(xhr.responseText)
                        if (response.images && response.images.length > 0) {
                            const image = response.images[Math.floor(Math.random() * response.images.length)]
                            downloadImage(image.url, `waifu-${image.image_id}`)
                        } else {
                            handleError("No images found on Waifu.im")
                        }
                    } catch (e) {
                        handleError("Failed to parse Waifu.im response: " + e)
                    }
                } else {
                    handleError(`Waifu.im request failed: ${xhr.status}`)
                }
            }
        }
        xhr.send()
    }

    // ========================
    // REDDIT
    // ========================
    function fetchRedditSubreddit(subreddit) {
        const url = `https://www.reddit.com/r/${subreddit}/hot.json?limit=100`
        print(`[RandomNetworkWallpaper] Fetching from Reddit r/${subreddit}`)

        const xhr = new XMLHttpRequest()
        xhr.open("GET", url)
        xhr.setRequestHeader("User-Agent", "QuickShell-Wallpaper/1.0")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        const response = JSON.parse(xhr.responseText)
                        const posts = response.data.children.filter(post => {
                            const url = post.data.url || ""
                            const isImage = url.match(/\.(jpg|jpeg|png|webp)$/i)
                            const nsfwOk = root.nsfwEnabled || !post.data.over_18
                            return isImage && nsfwOk
                        })
                        
                        if (posts.length > 0) {
                            const randomPost = posts[Math.floor(Math.random() * posts.length)]
                            downloadImage(randomPost.data.url, `reddit-${subreddit}-${randomPost.data.id}`)
                        } else {
                            handleError(`No suitable wallpapers found on r/${subreddit}`)
                        }
                    } catch (e) {
                        handleError("Failed to parse Reddit response: " + e)
                    }
                } else {
                    handleError(`Reddit request failed: ${xhr.status}`)
                }
            }
        }
        xhr.send()
    }

    // ========================
    // Download Helper
    // ========================
    Process {
        id: downloadProc
        property string targetPath: ""

        stdout: SplitParser {
            onRead: data => print("[RandomNetworkWallpaper] Download:", data)
        }

        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                root.handleSuccess(downloadProc.targetPath)
            } else {
                root.handleError("Download failed")
            }
        }
    }

    function downloadImage(url, filename) {
        let ext = "jpg"
        const extMatch = url.match(/\.(jpg|jpeg|png|webp|avif)(\?|$)/i)
        if (extMatch) ext = extMatch[1].toLowerCase()
        if (ext === "jpeg") ext = "jpg"

        const targetPath = `${downloadDir}/${filename}.${ext}`
        downloadProc.targetPath = targetPath

        print("[RandomNetworkWallpaper] Downloading:", url, "->", targetPath)
        downloadProc.exec(["curl", "-L", "-f", "-s", "-o", targetPath, url])
    }

    // ========================
    // IPC Handler
    // ========================
    IpcHandler {
        target: "randomWallpaper"

        function fetch(): void {
            root.fetchRandom("")
        }

        function fetchFrom(source: string): void {
            root.fetchRandom(source)
        }

        function source(name: string): void {
            root.setSource(name)
        }

        function listSources(): void {
            print("[RandomNetworkWallpaper] Available sources:")
            for (const key of root.sourceList) {
                const src = root.sources[key]
                print(`  - ${key}: ${src.name} - ${src.description}`)
            }
        }
    }
}
