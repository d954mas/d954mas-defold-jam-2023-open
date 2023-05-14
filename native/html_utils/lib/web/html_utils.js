var LibHtmlUtils = {


    HtmlHtmlUtilsHideBg: function () {
        let canvas_bg = document.getElementById("canvas-bg");
        if (canvas_bg) {
            canvas_bg.style.display = "none";
            canvas_bg.style.background = "";
            canvas_bg.remove()
        }
    },

    HtmlHtmlUtilsCanvasHaveFocus: function () {
       // console.log("Focus on:" + document.activeElement.id)
        return document.activeElement.id === 'canvas'
    },
    HtmlHtmlUtilsCanvasFocus: function () {
        document.getElementById("canvas").focus()
    },

}

mergeInto(LibraryManager.library, LibHtmlUtils);