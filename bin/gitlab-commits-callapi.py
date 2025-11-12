import subprocess
import json
import re
from datetime import datetime
import argparse
# import requests  # Tạm comment khi debug

def cut_after_pipe(s):
    """
    Cắt chuỗi trước ký tự '|' nếu có, trả về phần bên trái đã strip.
    Ví dụ: 'Eugene Lee|apikey:...' -> 'Eugene Lee'
    """
    return s.split('|', 1)[0].strip()

def extract_apikey(s):
    """
    Tìm và trả về apikey dạng 'apikey:xxxxxxxx...' từ chuỗi cho trước.
    Nếu không tìm thấy, trả về None.
    """
    m = re.search(r'apikey:[a-f0-9]+', s)
    return m.group(0) if m else None

def get_git_log(since, until, author=None):
    """
    Thực thi lệnh git log với tham số since, until và author (nếu có),
    lấy log commit dưới dạng JSON array.
    """
    git_cmd = [
        "git", "log", "--all",
        f"--since={since}",
        f"--until={until}",
        '--pretty=format:{"date":"%ad","hash":"%h","author":"%an","ref":"%D","msg":"%s","parents":"%P"},',
        "--date=format:%Y-%m-%d %H:%M:%S"
    ]
    if author:
        git_cmd.append(f"--author={author}")

    result = subprocess.run(git_cmd, capture_output=True, text=True)
    raw_output = "[" + result.stdout.strip().rstrip(",") + "]"
    try:
        return json.loads(raw_output)
    except json.JSONDecodeError as e:
        print("JSON decode error:", e)
        return []

def extract_op_id(message):
    """
    Tìm op_id dạng {OP#1234} trong message commit, trả về chuỗi số id hoặc None.
    """
    m = re.search(r"\{OP#(\d+)\}", message)
    return m.group(1) if m else None

def get_branch_for_hash(commit_hash):
    """
    Lấy danh sách branch chứa commit hash bằng lệnh:
    git branch --contains <hash>
    Trả về chuỗi các branch nối nhau bởi dấu phẩy.
    """
    try:
        result = subprocess.run(
            ["git", "branch", "--contains", commit_hash, "--format=%(refname:short)"],
            capture_output=True, text=True
        )
        branches = [line.strip() for line in result.stdout.splitlines() if line.strip()]
        return ", ".join(branches)
    except Exception:
        return ""

def get_child_commits_by_author(parent1, merge_hash, author):
    """
    Lấy các commit con trong khoảng từ parent1 tới merge_hash mà tác giả trùng author.
    Dùng lệnh git log <parent1>..<merge_hash> --pretty=format:%h|%an
    Trả về danh sách hash commit con.
    """
    try:
        if not parent1:
            return []

        result = subprocess.run(
            ["git", "log", f"{parent1}..{merge_hash}", "--pretty=format:%h|%an"],
            capture_output=True, text=True
        )
        lines = result.stdout.strip().splitlines()

        hashes = [
            line.split("|")[0] for line in lines
            if line.split("|")[1].strip().lower() == author.lower()
        ]
        return hashes
    except Exception:
        return []

def parse_commits(entries, include_working_hours=False):
    """
    Chuyển đổi danh sách commit raw (dict) sang danh sách commit chuẩn theo yêu cầu,
    phân loại event, type, lấy branch, child commits, apikey, op_id...
    Lọc commit theo giờ tăng ca hoặc cả giờ hành chính theo tham số include_working_hours.
    Đồng thời đếm số commit tăng ca và trong giờ.
    """
    commits = []
    count_stat = {"overtime": 0, "working": 0}

    for entry in entries:
        try:
            dt = datetime.strptime(entry["date"], "%Y-%m-%d %H:%M:%S")
            hour, minute = dt.hour, dt.minute
            is_overtime = hour < 8 or hour > 17 or (hour == 17 and minute > 30)
            if not include_working_hours and not is_overtime:
                # Bỏ commit trong giờ hành chính nếu không bao gồm
                continue

            if is_overtime:
                count_stat["overtime"] += 1
            else:
                count_stat["working"] += 1

            author_raw = entry["author"]
            author = author_raw.split('|',1)[0].strip()
            apikey_match = re.search(r'apikey:[a-f0-9]+', author_raw)
            apikey = apikey_match.group(0) if apikey_match else None

            parents = entry.get("parents", "").strip().split()
            is_merge = len(parents) > 1
            event_type = "merge" if is_merge else "commit"
            
            ref_info = entry.get("ref", "").strip()
            branch = ""
            m_branch = re.search(r'HEAD -> ([^,\s]+)', ref_info)
            if m_branch:
                branch = m_branch.group(1)
            elif "origin/" in ref_info:
                m_branch = re.search(r'origin/([^,\s]+)', ref_info)
                if m_branch:
                    branch = m_branch.group(1)
            elif ref_info:
                branch = ref_info.split(",")[0].strip()

            if not branch:
                branch = get_branch_for_hash(entry["hash"])

            child_commits = []
            if is_merge:
                child_commits = get_child_commits_by_author(parents[0], entry["hash"], author)

            commit_type = (
                "merge-with-contribution" if is_merge and child_commits else
                "merge-only" if is_merge else
                "commit"
            )

            op_id = None
            m_opid = re.search(r"\{OP#(\d+)\}", entry["msg"])
            if m_opid:
                op_id = m_opid.group(1)

            commit = {
                "author": author,
                "apikey": apikey,
                "date": dt.strftime("%d/%m/%Y"),
                "time": dt.strftime("%H:%M"),
                "hash": entry["hash"],
                "event": event_type,
                "type": commit_type,
                "branch": branch,
                "message": entry["msg"].strip(),
                "commits": child_commits,
                "op_id": op_id or ""
            }
            commits.append(commit)
        except Exception as e:
            print("Error parsing commit:", e)
            continue
    return commits, count_stat

def send_to_api(commits, url):
    # import requests
    # payload = {"commits": commits}
    # try:
    #     response = requests.post(url, json=payload, timeout=10)
    #     response.raise_for_status()
    #     print("Data sent successfully:", response.text)
    # except requests.RequestException as e:
    #     print("Error sending data:", e)
    pass

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="GitLab commits export & send API")
    parser.add_argument("--since", default="2025-06-01T00:00:00")
    parser.add_argument("--until", default="2025-06-30T23:59:59")
    parser.add_argument("--author", default=None, help="Filter by author name")
    parser.add_argument("--output", default="commits.json", help="Output JSON filename")
    parser.add_argument("--include-working-hours", action="store_true", help="Bao gồm commit trong giờ hành chính")
    args = parser.parse_args()

    entries = get_git_log(args.since, args.until, args.author)
    commits, count_stat = parse_commits(entries, include_working_hours=args.include_working_hours)

    # Chuẩn bị dữ liệu xuất ra, có trường summary và working rõ ràng
    output_data = {
        "summary": count_stat['overtime'],  # Số commit tăng ca
        "working": count_stat['working'],   # Số commit trong giờ (nếu dùng --include-working-hours)
        "commits": commits
    }

    print(json.dumps(output_data, ensure_ascii=False, indent=2))

    with open(args.output, "w", encoding="utf-8") as f:
        json.dump(output_data, f, ensure_ascii=False, indent=2)

    # Tạm comment khi debug gửi lên API
    # api_url = "https://pull-server.test/api/v1/git-commits"
    # send_to_api(output_data, api_url)
