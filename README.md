The first file in Repo

HD viết file 

### Mục lục

- [1. Viết tiêu đề](#viettieude)
- [2. Chèn thông tin](#chenthongtin)
- [3. Kiểu chữ](#kieuchu)
- [4. Trích dẫn, bo chữ](#trichdanbochu)
- [5. Tạo bảng](#taobang)
- [6. Viết mục lục](#vietmucluc)

<a name="viettieude"></a>
### 1. Viết tiêu đề:

```
- # 1.Tiêu đề cấp 1
```

# 1.Tiêu đề cấp 1

```
- ###### 6.Tiêu đề cấp 6
```
###### 6.Tiêu đề cấp 6

<a name="chenthongtin"></a>
### 2. Chèn thông tin 

```
- Chèn link: [Github](https://github.com)
```

[Github](https://github.com)

```
- Chèn ảnh online: <img src="link_anh_cua_ban"> (up ảnh lên http://i.imgur.com/, sau đó lấy link ảnh)
```

- Chèn ảnh offline: upload ảnh lên trên repo của github và điền link từ repo vào. Ví dụ `![nifi1](../imgs/nifi1.png)`

<a name="kieuchu"></a>
### 3. Kiểu chữ 

```
- In đậm: **từ cần in đậm**
```

**từ cần in đậm**

```
- Chữ nghiêng: *từ cần in nghiêng*
```

*từ cần in nghiêng*

<a name="trichdanbochu"></a>
### 4. Trích dẫn, bo chữ 

```
- `đoạn cần bo`
```

`đoạn cần bo`

- Bo nhiều dòng:

\```sh
auto eth0
iface eth0 inet static
ipaddress 10.10.10.10
\```

```sh
auto eth0
iface eth0 inet static
ipaddress 10.10.10.10
```

<a name="taobang"></a>
### 5. Tạo bảng

```
| Cột 1 Hàng 1 | Cột 2 | Cột 3| Cột 4 |
|--------------|-------|------|-------|
| Hàng 2 | 2 x 1 | 2 x 2 | 2 x 3 | 2 x 4 |
| Hàng 3 | 3 x 1 | 3 x 2 | 3 x 3 | 3 x 4 |
| Hàng 4 | 4 x 1 | 4 x 2 | 4 x 3 | 4 x 4 |
```

| Cột 1 Hàng 1 | Cột 2 | Cột 3| Cột 4 |
|--------------|-------|------|-------|
| Hàng 2 | 2 x 1 | 2 x 2 | 2 x 3 | 2 x 4 |
| Hàng 3 | 3 x 1 | 3 x 2 | 3 x 3 | 3 x 4 |
| Hàng 4 | 4 x 1 | 4 x 2 | 4 x 3 | 4 x 4 |

Mẹo: Sử dụng trang http://markdownlivepreview.com/ paste vào đó đoạn markdown bạn viết và xem trước để chỉnh sửa cho phù hợp.

<a name="vietmucluc"></a>
### 6. Viết mục lục

Chèn vào đầu của mỗi file cần tạo

Tên mục lục

```
### Mục lục
```

Tên các phần

```
[I. Mở đầu](#Modau)
```

Với 

- `[I. Mở đầu]` là tên header

- `(#Modau)` được đặt ở phía trước mỗi header theo mẫu `<a name="Modau"></a>`

Ví dụ:

```
<a name="Modau"></a>

### 1. Viết tiêu đề:
```

```
[II. Ngôn ngữ Markdown](#ngonngumarkdown)

- [1. Thẻ tiêu đề](#thetieude)

- [2. Chèn link, chèn ảnh](#chenlinkchenanh)

```