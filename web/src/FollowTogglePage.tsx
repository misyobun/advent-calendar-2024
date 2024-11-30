import { Console } from "console";
import React, { useState } from "react";

declare global {
  interface Window {
    followToggleExample?: {
      follow: (publicCalendarId: string) => Promise<void>;
      isFollowing: () => boolean;
    };
    __resolveFollowCalendar?: () => void;
    __rejectFollowCalendar?: () => void;
  }
}

type FollowToggleButtonProps = {
  isFollowed: boolean;
  onClick: () => void;
};

const FollowToggleButton: React.FC<FollowToggleButtonProps> = ({ isFollowed, onClick }) => {
  const buttonStyles = isFollowed
    ? "bg-red-500 hover:bg-red-600"
    : "bg-blue-400 hover:bg-blue-600";

  return (
    <button
      onClick={onClick}
      className={`${buttonStyles} text-white px-6 py-2 rounded-full transition duration-300`}
    >
      {isFollowed ? "フォロー解除する" : "フォローする"}
    </button>
  );
};

const FollowTogglePage: React.FC = () => {
  const [isFollowed, setIsFollowed] = useState<boolean>(false);

  const handleFollow = () => {
    if (window.followToggleExample) {
      window.followToggleExample
        .follow("sample-id")
        .then(() => {
          console.log("Swift側でのフォロー・フォロー解除処理完了")
          return window.followToggleExample?.isFollowing();
        })
        .then((following) => {
          console.log("JS側でのフォロー状態を元に再描画")
          setIsFollowed(!!following);
        })
        .catch(() => setIsFollowed(false));
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-100">
      <div className="bg-white p-8 rounded-lg shadow-lg text-center">
        <h1 className="text-2xl font-bold mb-4">フォロー操作</h1>
        <FollowToggleButton isFollowed={isFollowed} onClick={handleFollow} />
      </div>
    </div>
  );
};

export default FollowTogglePage;
