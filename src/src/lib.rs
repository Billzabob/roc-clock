#![allow(non_snake_case)]

mod glue;

use core::alloc::Layout;
use core::ffi::c_void;
use core::mem::MaybeUninit;
use glue::Metadata;
use std::io::Write;
use roc_std::{RocList, RocStr};
use std::time::Duration;

extern "C" {
    #[link_name = "roc__mainForHost_1_exposed_generic"]
    fn roc_main(output: *mut u8);

    #[link_name = "roc__mainForHost_size"]
    fn roc_main_size() -> i64;

    #[link_name = "roc__mainForHost_1__Fx_caller"]
    fn call_Fx(flags: *const u8, closure_data: *const u8, output: *mut u8);

    #[allow(dead_code)]
    #[link_name = "roc__mainForHost_1__Fx_size"]
    fn size_Fx() -> i64;

    #[link_name = "roc__mainForHost_1__Fx_result_size"]
    fn size_Fx_result() -> i64;
}

#[no_mangle]
pub unsafe extern "C" fn roc_alloc(size: usize, _alignment: u32) -> *mut c_void {
    libc::malloc(size)
}

#[no_mangle]
pub unsafe extern "C" fn roc_realloc(
    c_ptr: *mut c_void,
    new_size: usize,
    _old_size: usize,
    _alignment: u32,
) -> *mut c_void {
    libc::realloc(c_ptr, new_size)
}

#[no_mangle]
pub unsafe extern "C" fn roc_dealloc(c_ptr: *mut c_void, _alignment: u32) {
    libc::free(c_ptr)
}

#[no_mangle]
pub unsafe extern "C" fn roc_panic(msg: &RocStr, tag_id: u32) {
    match tag_id {
        0 => {
            eprintln!("Roc crashed with:\n\n\t{}\n", msg.as_str());

            print_backtrace();
            std::process::exit(1);
        }
        1 => {
            eprintln!("The program crashed with:\n\n\t{}\n", msg.as_str());

            print_backtrace();
            std::process::exit(1);
        }
        _ => todo!(),
    }
}

#[cfg(unix)]
#[no_mangle]
pub unsafe extern "C" fn roc_getppid() -> libc::pid_t {
    libc::getppid()
}

#[cfg(unix)]
#[no_mangle]
pub unsafe extern "C" fn roc_mmap(
    addr: *mut libc::c_void,
    len: libc::size_t,
    prot: libc::c_int,
    flags: libc::c_int,
    fd: libc::c_int,
    offset: libc::off_t,
) -> *mut libc::c_void {
    libc::mmap(addr, len, prot, flags, fd, offset)
}

#[cfg(unix)]
#[no_mangle]
pub unsafe extern "C" fn roc_shm_open(
    name: *const libc::c_char,
    oflag: libc::c_int,
    mode: libc::mode_t,
) -> libc::c_int {
    libc::shm_open(name, oflag, mode as libc::c_uint)
}

fn print_backtrace() {
    eprintln!("Here is the call stack that led to the crash:\n");

    let mut entries = Vec::new();

    #[derive(Default)]
    struct Entry {
        pub fn_name: String,
        pub filename: Option<String>,
        pub line: Option<u32>,
        pub col: Option<u32>,
    }

    backtrace::trace(|frame| {
        backtrace::resolve_frame(frame, |symbol| {
            if let Some(fn_name) = symbol.name() {
                let fn_name = fn_name.to_string();

                if should_show_in_backtrace(&fn_name) {
                    let mut entry: Entry = Default::default();

                    entry.fn_name = format_fn_name(&fn_name);

                    if let Some(path) = symbol.filename() {
                        entry.filename = Some(path.to_string_lossy().into_owned());
                    };

                    entry.line = symbol.lineno();
                    entry.col = symbol.colno();

                    entries.push(entry);
                }
            } else {
                entries.push(Entry {
                    fn_name: "???".to_string(),
                    ..Default::default()
                });
            }
        });

        true // keep going to the next frame
    });

    for entry in entries {
        eprintln!("\t{}", entry.fn_name);

        if let Some(filename) = entry.filename {
            eprintln!("\t\t{filename}");
        }
    }

    eprintln!("\nOptimizations can make this list inaccurate! If it looks wrong, try running without `--optimize` and with `--linker=legacy`\n");
}

fn should_show_in_backtrace(fn_name: &str) -> bool {
    let is_from_rust = fn_name.contains("::");
    let is_host_fn = fn_name.starts_with("roc_panic")
        || fn_name.starts_with("_Effect_effect")
        || fn_name.starts_with("_roc__")
        || fn_name.starts_with("rust_main")
        || fn_name == "_main";

    !is_from_rust && !is_host_fn
}

fn format_fn_name(fn_name: &str) -> String {
    // e.g. convert "_Num_sub_a0c29024d3ec6e3a16e414af99885fbb44fa6182331a70ab4ca0886f93bad5"
    // to ["Num", "sub", "a0c29024d3ec6e3a16e414af99885fbb44fa6182331a70ab4ca0886f93bad5"]
    let mut pieces_iter = fn_name.split("_");

    if let (_, Some(module_name), Some(name)) =
        (pieces_iter.next(), pieces_iter.next(), pieces_iter.next())
    {
        display_roc_fn(module_name, name)
    } else {
        "???".to_string()
    }
}

fn display_roc_fn(module_name: &str, fn_name: &str) -> String {
    let module_name = if module_name == "#UserApp" {
        "app"
    } else {
        module_name
    };

    let fn_name = if fn_name.parse::<u64>().is_ok() {
        "(anonymous function)"
    } else {
        fn_name
    };

    format!("\u{001B}[36m{module_name}\u{001B}[39m.{fn_name}")
}

#[no_mangle]
pub unsafe extern "C" fn roc_memcpy(dst: *mut c_void, src: *mut c_void, n: usize) -> *mut c_void {
    libc::memcpy(dst, src, n)
}

#[no_mangle]
pub unsafe extern "C" fn roc_memset(dst: *mut c_void, c: i32, n: usize) -> *mut c_void {
    libc::memset(dst, c, n)
}

#[no_mangle]
pub extern "C" fn rust_main() {
    let size = unsafe { roc_main_size() } as usize;
    let layout = Layout::array::<u8>(size).unwrap();

    unsafe {
        // TODO allocate on the stack if it's under a certain size
        let buffer = std::alloc::alloc(layout);

        roc_main(buffer);

        call_the_closure(buffer);

        std::alloc::dealloc(buffer, layout);
    }
}

unsafe fn call_the_closure(closure_data_ptr: *const u8) -> u8 {
    let size = size_Fx_result() as usize;
    let layout = Layout::array::<u8>(size).unwrap();
    let buffer = std::alloc::alloc(layout) as *mut u8;

    call_Fx(
        // This flags pointer will never get dereferenced
        MaybeUninit::uninit().as_ptr(),
        closure_data_ptr as *const u8,
        buffer as *mut u8,
    );

    std::alloc::dealloc(buffer, layout);

    // TODO return the u8 exit code returned by the Fx closure
    0
}

#[no_mangle]
pub extern "C" fn roc_fx_sleep(duration: u64) {
    use std::thread;
    thread::sleep(Duration::from_millis(duration));
}

#[no_mangle]
pub extern "C" fn roc_fx_setPinHigh(pin: u8) {
    use rppal::gpio::Gpio;

    match Gpio::new() {
        Ok(gpio) =>
            match gpio.get(pin) {
                Ok(p) => {
                    let mut pin = p.into_output();
                    pin.set_reset_on_drop(false);
                    pin.set_high();
                },
                Err(e) => println!("Failed to get pin {}", e),
            },
        Err(e) => println!("Failed to access GPIO {}", e),
    };
}

#[no_mangle]
pub extern "C" fn roc_fx_setPinLow(pin: u8) {
    use rppal::gpio::Gpio;

    match Gpio::new() {
        Ok(gpio) =>
            match gpio.get(pin) {
                Ok(p) => {
                    let mut pin = p.into_output();
                    pin.set_reset_on_drop(false);
                    pin.set_low();
                },
                Err(e) => println!("Failed to get pin {}", e),
            },
        Err(e) => println!("Failed to access GPIO {}", e),
    };
}

#[no_mangle]
pub extern "C" fn roc_fx_pwm(frequency: f64, duty_cycle: f64) {
    use rppal::pwm::Pwm;
    use rppal::pwm::Channel;
    use rppal::pwm::Polarity;

    match Pwm::with_frequency(Channel::Pwm0, frequency, duty_cycle, Polarity::Normal, true) {
        Ok(mut pwm) => pwm.set_reset_on_drop(false),
        Err(e) => println!("Failed to set PWM {}", e),
    };
}

#[no_mangle]
pub extern "C" fn roc_fx_writeBytes(address: u16, bytes: &RocList<u8>) {
    use rppal::i2c::I2c;

    match I2c::new() {
        Ok(mut i2c) => match i2c.set_slave_address(address) {
            Ok(_) => {
                match i2c.write(bytes.as_slice()) {
                    Ok(_) => (),
                    Err(e) => {
                        println!("Failed to write {}", e);
                    },
                }
            },
            Err(e) => {
                println!("Failed to set address {}", e);
            },
        },
        Err(e) => {
            println!("Failed to create i2c {}", e);
        },
    };
}

#[no_mangle]
pub extern "C" fn roc_fx_readBytes(address: u16, length: usize) -> RocList<u8> {
    use rppal::i2c::I2c;

    let mut data = vec![0; length];

    match I2c::new() {
        Ok(mut i2c) => {
            match i2c.set_slave_address(address) {
                Ok(_) => {
                    match i2c.read(&mut data) {
                        Ok(_) => (),
                        Err(e) => {
                            println!("Failed to read {}", e);
                        },
                    }
                },
                Err(e) => {
                    println!("Failed to set address {}", e);
                },
            }
        },
        Err(e) => {
            println!("Failed to create i2c {}", e);
        },
    };

    RocList::from(data.as_slice())
}

#[no_mangle]
pub extern "C" fn roc_fx_stdinLine() -> RocStr {
    use std::io::BufRead;

    let stdin = std::io::stdin();
    let line1 = stdin.lock().lines().next().unwrap().unwrap();

    RocStr::from(line1.as_str())
}

#[no_mangle]
pub extern "C" fn roc_fx_stdoutLine(line: &RocStr) {
    let string = line.as_str();
    println!("{}", string);
}

#[no_mangle]
pub extern "C" fn roc_fx_stdoutWrite(text: &RocStr) {
    let string = text.as_str();
    print!("{}", string);
    std::io::stdout().flush().unwrap();
}

#[no_mangle]
pub extern "C" fn roc_fx_stderrLine(line: &RocStr) {
    let string = line.as_str();
    eprintln!("{}", string);
}

#[no_mangle]
pub extern "C" fn roc_fx_stderrWrite(text: &RocStr) {
    let string = text.as_str();
    eprint!("{}", string);
    std::io::stderr().flush().unwrap();
}

#[no_mangle]
pub extern "C" fn roc_fx_sendRequest(roc_request: &glue::Request) -> glue::Response {
    let mut builder = reqwest::blocking::ClientBuilder::new();

    if roc_request.timeout.discriminant() == glue::discriminant_TimeoutConfig::TimeoutMilliseconds {
        let ms: &u64 = unsafe { roc_request.timeout.as_TimeoutMilliseconds() };
        builder = builder.timeout(Duration::from_millis(*ms));
    }

    let client = match builder.build() {
        Ok(c) => c,
        Err(_) => {
            return glue::Response::NetworkError; // TLS backend cannot be initialized
        }
    };

    let method = match roc_request.method {
        glue::Method::Connect => reqwest::Method::CONNECT,
        glue::Method::Delete => reqwest::Method::DELETE,
        glue::Method::Get => reqwest::Method::GET,
        glue::Method::Head => reqwest::Method::HEAD,
        glue::Method::Options => reqwest::Method::OPTIONS,
        glue::Method::Patch => reqwest::Method::PATCH,
        glue::Method::Post => reqwest::Method::POST,
        glue::Method::Put => reqwest::Method::PUT,
        glue::Method::Trace => reqwest::Method::TRACE,
    };

    let url = roc_request.url.as_str();

    let mut req_builder = client.request(method, url);
    for header in roc_request.headers.iter() {
        let (name, value) = unsafe { header.as_Header() };
        req_builder = req_builder.header(name.as_str(), value.as_str());
    }
    if roc_request.body.discriminant() == glue::discriminant_Body::Body {
        let (mime_type_tag, body_byte_list) = unsafe { roc_request.body.as_Body() };
        let mime_type_str: &RocStr = unsafe { mime_type_tag.as_MimeType() };

        req_builder = req_builder.header("Content-Type", mime_type_str.as_str());
        req_builder = req_builder.body(body_byte_list.as_slice().to_vec());
    }

    let request = match req_builder.build() {
        Ok(req) => req,
        Err(err) => {
            return glue::Response::BadRequest(RocStr::from(err.to_string().as_str()));
        }
    };

    match client.execute(request) {
        Ok(response) => {
            let status = response.status();
            let status_str = status.canonical_reason().unwrap_or_else(|| status.as_str());

            let headers_iter = response.headers().iter().map(|(name, value)| {
                glue::Header::Header(
                    RocStr::from(name.as_str()),
                    RocStr::from(value.to_str().unwrap_or_default()),
                )
            });

            let metadata = Metadata {
                headers: RocList::from_iter(headers_iter),
                statusText: RocStr::from(status_str),
                url: RocStr::from(url),
                statusCode: status.as_u16(),
            };

            let bytes = response.bytes().unwrap_or_default();
            let body: RocList<u8> = RocList::from_iter(bytes.into_iter());

            if status.is_success() {
                glue::Response::GoodStatus(metadata, body)
            } else {
                glue::Response::BadStatus(metadata, body)
            }
        }
        Err(err) => {
            if err.is_timeout() {
                glue::Response::Timeout
            } else if err.is_request() {
                glue::Response::BadRequest(RocStr::from(err.to_string().as_str()))
            } else {
                glue::Response::NetworkError
            }
        }
    }
}

