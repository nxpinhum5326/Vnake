import gx
import gg
import time
import rand

const win_width = 500
const win_height = 512

const bg_color = gx.rgb(130, 254, 111) //green
const snake_color = gx.rgb(70, 78, 79) //gray
const apple_color = gx.rgb(255, 0, 0) //red

struct Snake {
mut:
    x     []int
    y     []int
    dir_x int
    dir_y int
    length int
}

fn (mut s Snake) move() {
    for i := s.length - 1; i > 0; i-- {
        s.x[i] = s.x[i - 1]
        s.y[i] = s.y[i - 1]
    }
    s.x[0] += s.dir_x
    s.y[0] += s.dir_y
}


fn (mut s Snake) update() {
    s.move()
}

fn (mut s Snake) grow() {
    s.x << s.x[s.length - 1]
    s.y << s.y[s.length - 1]
    s.length++
}

struct Apple {
mut:
    x int
    y int
}

struct App {
mut:
    gg               &gg.Context = unsafe { nil }
    snake            Snake
    apple            Apple
    score            int
    max_score        int
    width            int = win_width
    height           int = win_height
}

fn (mut app App) init() {
    app.snake = Snake{
        x: [100, 90, 80],
        y: [100, 100, 100],
        dir_x: 10,
        dir_y: 0,
        length: 3
    }
    app.spawn_apple()
}

fn (mut app App) spawn_apple() {
    mut new_apple := Apple{}
    mut valid_pos := false

    for !valid_pos {
        apple_x := rand.int_in_range(0, int(app.width / 10)) or { continue }
        apple_y := rand.int_in_range(0, int(app.height / 10)) or { continue }
        
        new_apple.x = apple_x * 10
        new_apple.y = apple_y * 10
        
        valid_pos = true

        for i in 0..app.snake.length {
            if app.snake.x[i] == new_apple.x && app.snake.y[i] == new_apple.y {
                valid_pos = false
                break
            }
        }
    }
    app.apple = new_apple
}

fn (mut app App) check_collision() bool {
    if app.snake.x[0] < 0 || app.snake.x[0] >= app.width || app.snake.y[0] < 0 || app.snake.y[0] >= app.height {
        println("Wall collision detected!")
        return true
    }

    for i in 1..app.snake.length {
        if app.snake.x[0] == app.snake.x[i] && app.snake.y[0] == app.snake.y[i] {
            println("Self collision detected!")
            return true
        }
    }

    return false
}

const tick_interval = 50

fn (mut app App) tick() {
    app.snake.update()
    
//restart
    if app.check_collision() {
        if app.score > app.max_score {
            app.max_score = app.score
        }

        app.snake = Snake{
            x: [100, 90, 80],
            y: [100, 100, 100],
            dir_x: 10,
            dir_y: 0,
            length: 3
        }
        app.score = 0
    }

    if app.snake.x[0] == app.apple.x && app.snake.y[0] == app.apple.y {
        app.snake.grow()
        app.score++
        app.spawn_apple()
    }

    time.sleep(tick_interval * time.millisecond)
}

fn frame(mut app App) {
    app.tick()
    app.gg.begin()
    app.display()
    app.gg.end()
}

fn (app &App) display() {
    app.gg.draw_rect_filled(0, 0, app.width, app.height, bg_color)

    for i in 0..app.snake.length {
        app.gg.draw_rect_filled(app.snake.x[i], app.snake.y[i], 10, 10, snake_color)
    }

    app.gg.draw_rect_filled(app.apple.x, app.apple.y, 10, 10, apple_color)
    app.gg.draw_rect_filled(0, 510, app.width, 5, gx.rgb(33, 25, 40))
    app.gg.draw_text_def(10, 25, "Score: ${app.score}")
    app.gg.draw_text_def(10, 50, "Max Score: ${app.max_score}")
}

// check; https://modules.vlang.io/sokol.sapp.html#EventType & https://modules.vlang.io/gg.html#Event
fn on_event(e &gg.Event, mut app App) {
    if e.typ == .key_down {
        match e.key_code {
            .up { app.snake.dir_x = 0; app.snake.dir_y = -10 }
            .down { app.snake.dir_x = 0; app.snake.dir_y = 10 }
            .left { app.snake.dir_x = -10; app.snake.dir_y = 0 }
            .right { app.snake.dir_x = 10; app.snake.dir_y = 0 }
            else {}
        }
    }
}

// main
fn main() {
    mut app := App{}
    app.gg = gg.new_context(
        bg_color:      bg_color
        width:         win_width
        height:        win_height
        create_window: true
        window_title:  "snake game"
        frame_fn:      frame
        event_fn:      on_event
        user_data:     &app
    )
    app.init()
    app.gg.run()
}
