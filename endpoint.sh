#!/bin/bash

set -eo pipefail


# Testing
GITHUB_REF_NAME='feature/testing'
#GITHUB_REF_NAME='main'
main_branch_name='main'
develop_branch_name='feature/testing'
DEBUG=true
GITHUB_OUTPUT=githubenvfile

debugmsg() {
  if [[ $DEBUG == "true" ]]; then
     echo $1
  fi
}

setOutput() {
    echo "${1}=${2}" >> "${GITHUB_OUTPUT}"
}

getCurrentTags() {
  STABLE_TAG=`git tag | grep -v 'develop' | grep -v 'main' | tr -d v | sort -n -k 1,1 -k 2,2 -k 3,3 -k 4,4 -t \. | grep -v pre | tail -1`
  debugmsg "STABLE: $STABLE_TAG"
  PRE_TAG=`git tag | grep -v 'develop' | grep -v 'main' | tr -d v | sort -n -k 1,1 -k 2,2 -k 3,3 -k 4,4 -t \. | grep pre | tail -1`
  debugmsg "PRE: $PRE_TAG"
  STABLE_MAJOR=`echo $STABLE_TAG | cut -f 1 -d\.`
  STABLE_MINOR=`echo $STABLE_TAG | cut -f 2 -d\.`
  STABLE_FIX=`echo $STABLE_TAG | cut -f 3 -d\.`
  debugmsg "Stable contains: $STABLE_MAJOR.$STABLE_MINOR.$STABLE_FIX"
  PRE_MAJOR=`echo $PRE_TAG | cut -f 1 -d\.`
  PRE_MINOR=`echo $PRE_TAG | cut -f 2 -d\.`
  PRE_FIX=`echo $PRE_TAG | sed -e "s/-pre//" |  cut -f 3 -d\.`
  PRE_NUMBER=`echo $PRE_TAG |  cut -f 4 -d\.`
  debugmsg "Pre contains: $PRE_MAJOR.$PRE_MINOR.$PRE_FIX-pre.$PRE_NUMBER"

}

getMergeBranches() {
  MSG=`git log -1 --pretty=%B | head -1`
  debugmsg "MSG: $MSG"
  SOURCE=`echo $MSG | rev | cut -f 1 -d " " | rev | cut -f 2- -d"/"`
  debugmsg "SOURCE: $SOURCE"
  TARGET=$GITHUB_REF_NAME
  debugmsg "TARGET: $TARGET"
}

calculateDevelopTag() {
  if [[ $STABLE_MAJOR -gt $PRE_MAJOR ]]; then
    NEW_MAJOR=$STABLE_MAJOR
    let "NEW_MINOR=STABLE_MINOR+1"
    NEW_FIX=0
    NEW_NUMBER=0
  elif [[ $STABLE_MINOR -gt $PRE_MINOR ]]; then
    NEW_MAJOR=$PRE_MAJOR
    let "NEW_MINOR=STABLE_MINOR+1"
    NEW_FIX=0
    NEW_NUMBER=0
  elif [[ $STABLE_FIX -gt $PRE_FIX ]]; then
    NEW_MAJOR=$PRE_MAJOR
    let "NEW_MINOR=STABLE_MINOR+1"
    NEW_FIX=0
    NEW_NUMBER=0
  else
    NEW_MAJOR=$PRE_MAJOR
    NEW_MINOR=$PRE_MINOR
    NEW_FIX=$PRE_FIX
    let "NEW_NUMBER=PRE_NUMBER+1"
  fi 
}

calculateMainFixTag() {
  NEW_MAJOR=$STABLE_MAJOR
  NEW_MINOR=$STABLE_MINOR
  let "NEW_FIX=STABLE_FIX+1"
}

calculateMainMinorTag() {
  NEW_MAJOR=$STABLE_MAJOR
  let "NEW_MINOR=STABLE_MINOR+1"
  NEW_FIX=0
}

# First check if i am in main of develop branch
MY_BRANCH=`git rev-parse --abbrev-ref HEAD`

getMergeBranches
getCurrentTags

debugmsg 
debugmsg "Starting check for $MY_BRANCH , $TARGET , $SOURCE"
# If branch missmatch, throw error
if [[ "$MY_BRANCH" != "$TARGET" ]]; then
  echo "$MY_BRANCH does not match $TARGET!"
  exit 2
fi

if [[ "$TARGET" == "${main_branch_name}" ]]; then
  if [[ "$SOURCE" == "develop" ]]; then
    debugmsg "From develop"
    calculateMainMinorTag
  elif [[ "$SOURCE" =~ ^(bugfix|hotfix)/ ]]; then
    debugmsg "From bugfix/hotfix"
    calculateMainFixTag
  else 
    echo "Merge from other branch, throw error"
    exit 2
  fi
  NEW_TAG=$NEW_MAJOR.$NEW_MINOR.$NEW_FIX
  CURRENT_TAG=$STABLE_TAG
  debugmsg "New stable tag $NEW_TAG"
# In develop branch, we always increase number 
elif  [[ "$TARGET" == "${develop_branch_name}" ]]; then
  debugmsg "In develop"
  calculateDevelopTag
  NEW_TAG=$NEW_MAJOR.$NEW_MINOR.$NEW_FIX-pre.$NEW_NUMBER
  CURRENT_TAG=$PRE_TAG
fi
debugmsg "New tag $NEW_TAG"
debugmsg "Current tag $CURRENT_TAG"
setOutput NEW_TAG $NEW_TAG
setOutput CURRENT_TAG $CURRENT_TAG