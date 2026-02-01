
function cutConcaveCorner(ctx, r, corner) {
    ctx.beginPath()

    switch (corner) {
    case "topLeft":
        ctx.moveTo(0, 0)
        ctx.arc(0, 0, r, 0, Math.PI / 2)
        ctx.lineTo(0, 0)
        break

    case "topRight":
        ctx.moveTo(r, 0)
        ctx.arc(r, 0, r, Math.PI / 2, Math.PI)
        ctx.lineTo(r, 0)
        break

    case "bottomRight":
        ctx.moveTo(r, r)
        ctx.arc(r, r, r, Math.PI, 1.5 * Math.PI)
        ctx.lineTo(r, r)
        break

    case "bottomLeft":
        ctx.moveTo(0, r)
        ctx.arc(0, r, r, 1.5 * Math.PI, 2 * Math.PI)
        ctx.lineTo(0, r)
        break
    }

    ctx.closePath()
    ctx.fill()
}
