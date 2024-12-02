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

  const onFollowToggleButtonClick = async () => {
    try {
      await window.followToggleExample?.follow("sample-id");
      const following = await window.followToggleExample?.isFollowing();
      setIsFollowed(!!following);
    } catch (e) {
      setIsFollowed(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-100">
      <div className="bg-white p-8 rounded-lg shadow-lg text-center">
        <h1 className="text-2xl font-bold mb-4">フォロー操作</h1>
        <FollowToggleButton isFollowed={isFollowed} onClick={onFollowToggleButtonClick} />
      </div>
    </div>
  );
};

export default FollowTogglePage;
