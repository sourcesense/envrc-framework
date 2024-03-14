#!/usr/bin/env bash

# use as: ./release.sh vX.Y.Z
version="$1"
if [[ -z "$version" ]]; then
    echo >&2 "Missing version, please give a single parameter with version."
    exit 1
fi

sedi=(-i) # use "${sedi[@]}" instead of -i in sed options
case "$(uname)" in
    Darwin*) sedi=(-i "") ;;
esac

orgName="sourcesense"
repoName="envrc-framework"

echo "Bumping version to $version on all *.sh and .*.sh files"

for file in *.sh .*.sh; do
    sed "${sedi[@]}" -e "s#\"\(https://raw.githubusercontent.com/${orgName}/${repoName}\)/\(.*\)/\(.*\)\"#\"\1/${version}/\3\"#g" "${file}"
done

echo "Clearing SHAs on all *.sh and .*.sh files"
for targetFile in *.sh .*.sh; do
    sed "${sedi[@]}" -e "s#\(\"https://raw.githubusercontent.com/${orgName}/${repoName}/${version}/${file}\"\) \"sha256.*\"#\1 \"sha256-EMPTY\"#g" "${targetFile}"
done

echo "Searching for stable SHAs on all *.sh and .*.sh files"

getHashes()
{
    sha512sum ./.*.sh ./*.sh | tr -s " "
}

round=1

while :; do
    echo -n "Round #$round ... "

    initialHashes="$(getHashes)"
    for file in *.sh .*.sh; do
        hash=$(openssl dgst -sha256 -binary "$file" | openssl base64 -A)
        cleanedHash="$(echo -e "sha256-$hash" | tr "/" "_")"
        while IFS= read -r targetFile; do
            sed "${sedi[@]}" -e "s#\(\"https://raw.githubusercontent.com/${orgName}/${repoName}/${version}/${file}\"\) \"sha256.*\"#\1 \"$cleanedHash\"#g" "${targetFile}"
        done < <(grep -l "$file" ./*.sh ./.*.sh 2>/dev/null)
    done
    newHashes="$(getHashes)"
    if [[ "$newHashes" == "$initialHashes" ]]; then
        echo "no more changes, done. Found stable hashes in $((round - 1)) rounds."
        break
    else
        enumerateChangedFiles()
        {
            local initialHashes="$1"
            local newHashes="$2"
            local changedFiles=""
            while IFS= read -r line; do
                local file
                file="$(echo "$line" | cut -d " " -f 3)"
                cleanedFile="${file:2}"
                if [[ "$changedFiles" == "" ]]; then
                    changedFiles="$cleanedFile"
                else
                    changedFiles="$changedFiles, $cleanedFile"
                fi
            done < <(diff <(echo "$initialHashes") <(echo "$newHashes") | grep "^>")
            echo "$changedFiles"
        }
        echo "detected changes in $(enumerateChangedFiles "$initialHashes" "$newHashes"), running another round."
        round=$((round + 1))
    fi
done
